# Lock Handler Resource
# This resource detects and removes Azure resource locks BEFORE attempting to delete
# diagnostic settings. This prevents "ScopeLocked" errors when diagnostic settings
# reference locked resources (e.g., storage accounts).
#
# Triggers when diagnostic settings are being removed (not just on destroy)

resource "null_resource" "lock_handler" {
  # Trigger whenever the set of diagnostic settings changes
  # This ensures locks are removed before diagnostic settings deletion
  triggers = {
    diagnostic_settings = jsonencode(keys(azurerm_monitor_diagnostic_setting.diagnostic_setting_logs))
  }

  # Check and remove locks BEFORE any changes (create/update/destroy)
  provisioner "local-exec" {
    command = <<-SCRIPT
      #!/bin/bash
      set -e
      
      echo "==================== Azure Lock Handler (Pre-Change) ===================="
      echo "Checking for locks on resources with diagnostic settings..."
      
      # Get subscription ID from Azure CLI
      SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null || echo "")
      
      if [ -z "$SUBSCRIPTION_ID" ]; then
        echo "⚠️  Warning: Unable to detect Azure subscription. Skipping lock check."
        echo "Make sure you're logged in with: az login"
        exit 0
      fi
      
      echo "✓ Detected subscription: $SUBSCRIPTION_ID"
      
      # Get list of diagnostic settings from current state
      echo ""
      echo "Identifying resources with diagnostic settings..."
      
      DIAG_SETTINGS=$(terraform state list 2>/dev/null | grep 'azurerm_monitor_diagnostic_setting.diagnostic_setting_logs' || echo "")
      
      if [ -z "$DIAG_SETTINGS" ]; then
        echo "✓ No diagnostic settings found in state - no locks to check"
        exit 0
      fi
      
      LOCKS_FOUND=0
      LOCKS_REMOVED=0
      
      # For each diagnostic setting, extract the target resource ID and check for locks
      echo "$DIAG_SETTINGS" | while read DIAG_SETTING_KEY; do
        if [ -n "$DIAG_SETTING_KEY" ]; then
          # Get the target resource ID from the diagnostic setting
          TARGET_RESOURCE_ID=$(terraform state show "$DIAG_SETTING_KEY" 2>/dev/null | grep 'target_resource_id' | head -1 | awk '{print $3}' | tr -d '"' || echo "")
          
          if [ -n "$TARGET_RESOURCE_ID" ]; then
            # Extract resource type, name, and resource group from the ID
            RESOURCE_TYPE=$(echo "$TARGET_RESOURCE_ID" | awk -F'/providers/' '{print $2}' | awk -F'/' '{print $1"/"$2}')
            RESOURCE_NAME=$(echo "$TARGET_RESOURCE_ID" | awk -F'/' '{print $NF}')
            RESOURCE_GROUP=$(echo "$TARGET_RESOURCE_ID" | awk -F'/resourceGroups/' '{print $2}' | awk -F'/' '{print $1}')
            
            # Handle nested resources (e.g., storage account services)
            if echo "$TARGET_RESOURCE_ID" | grep -q "storageAccounts.*Services"; then
              # Extract parent storage account info
              PARENT_RESOURCE_ID=$(echo "$TARGET_RESOURCE_ID" | sed 's|/blobServices/.*||; s|/fileServices/.*||; s|/queueServices/.*||; s|/tableServices/.*||')
              RESOURCE_TYPE="Microsoft.Storage/storageAccounts"
              RESOURCE_NAME=$(echo "$PARENT_RESOURCE_ID" | awk -F'/storageAccounts/' '{print $2}' | awk -F'/' '{print $1}')
            fi
            
            if [ -n "$RESOURCE_GROUP" ] && [ -n "$RESOURCE_NAME" ] && [ -n "$RESOURCE_TYPE" ]; then
              # Check for locks on this specific resource
              RESOURCE_LOCKS=$(az lock list \
                --resource-group "$RESOURCE_GROUP" \
                --resource-name "$RESOURCE_NAME" \
                --resource-type "$RESOURCE_TYPE" \
                --query "[].{name:name, id:id, level:level}" \
                -o json 2>/dev/null || echo "[]")
              
              if [ "$RESOURCE_LOCKS" != "[]" ] && [ -n "$RESOURCE_LOCKS" ]; then
                LOCK_COUNT=$(echo "$RESOURCE_LOCKS" | jq 'length')
                LOCKS_FOUND=$((LOCKS_FOUND + LOCK_COUNT))
                
                echo ""
                echo "⚠️  Found $LOCK_COUNT lock(s) on: $RESOURCE_NAME ($RESOURCE_TYPE)"
                echo "$RESOURCE_LOCKS" | jq -r '.[] | "    - \(.name) (\(.level))"'
                
                # Remove each lock
                echo "$RESOURCE_LOCKS" | jq -r '.[].id' | while read LOCK_ID; do
                  if [ -n "$LOCK_ID" ]; then
                    LOCK_NAME=$(echo "$RESOURCE_LOCKS" | jq -r ".[] | select(.id==\"$LOCK_ID\") | .name")
                    echo "    → Removing lock: $LOCK_NAME"
                    if az lock delete --ids "$LOCK_ID" 2>/dev/null; then
                      echo "      ✓ Lock removed successfully"
                      LOCKS_REMOVED=$((LOCKS_REMOVED + 1))
                    else
                      echo "      ⚠️  Failed to remove lock (may lack permissions)"
                    fi
                  fi
                done
              fi
              
              # Also check for locks at the resource group level (these also block child resource operations)
              RG_LOCKS=$(az lock list \
                --resource-group "$RESOURCE_GROUP" \
                --query "[?!contains(id, '/providers/Microsoft.Storage/') && !contains(id, '/providers/Microsoft.Network/') && !contains(id, '/providers/Microsoft.Compute/') && contains(id, '/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Authorization/locks')].{name:name, id:id, level:level}" \
                -o json 2>/dev/null || echo "[]")
              
              if [ "$RG_LOCKS" != "[]" ] && [ -n "$RG_LOCKS" ] && [ "$(echo "$RG_LOCKS" | jq 'length')" -gt 0 ]; then
                LOCK_COUNT=$(echo "$RG_LOCKS" | jq 'length')
                LOCKS_FOUND=$((LOCKS_FOUND + LOCK_COUNT))
                
                echo ""
                echo "⚠️  Found $LOCK_COUNT RG-level lock(s) in: $RESOURCE_GROUP"
                echo "$RG_LOCKS" | jq -r '.[] | "    - \(.name) (\(.level))"'
                echo "    (RG-level locks also prevent child resource operations)"
                
                # Remove RG-level locks
                echo "$RG_LOCKS" | jq -r '.[].id' | while read LOCK_ID; do
                  if [ -n "$LOCK_ID" ]; then
                    LOCK_NAME=$(echo "$RG_LOCKS" | jq -r ".[] | select(.id==\"$LOCK_ID\") | .name")
                    echo "    → Removing RG lock: $LOCK_NAME"
                    if az lock delete --ids "$LOCK_ID" 2>/dev/null; then
                      echo "      ✓ Lock removed successfully"
                      LOCKS_REMOVED=$((LOCKS_REMOVED + 1))
                    else
                      echo "      ⚠️  Failed to remove lock (may lack permissions)"
                    fi
                  fi
                done
              fi
            fi
          fi
        fi
      done
      
      echo ""
      echo "==================== Lock Check Complete ===================="
      if [ $LOCKS_FOUND -gt 0 ]; then
        echo "✓ Found and processed $LOCKS_FOUND lock(s)"
        if [ $LOCKS_REMOVED -gt 0 ]; then
          echo "✓ Successfully removed $LOCKS_REMOVED lock(s)"
        fi
        echo ""
        echo "Terraform will now proceed with diagnostic settings changes."
      else
        echo "✓ No locks found on resources with diagnostic settings"
      fi
      echo ""
    SCRIPT
  }

  # Also run on destroy to handle full cleanup
  provisioner "local-exec" {
    when    = destroy
    command = <<-SCRIPT
      #!/bin/bash
      set -e
      
      echo "==================== Azure Lock Handler ===================="
      echo "Checking for locks on resources with diagnostic settings being removed..."
      
      # Get subscription ID from Azure CLI
      SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null || echo "")
      
      if [ -z "$SUBSCRIPTION_ID" ]; then
        echo "⚠️  Warning: Unable to detect Azure subscription. Skipping lock check."
        echo "Make sure you're logged in with: az login"
        exit 0
      fi
      
      echo "✓ Detected subscription: $SUBSCRIPTION_ID"
      
      # Get list of diagnostic settings being removed from terraform plan
      echo ""
      echo "Identifying resources with diagnostic settings being removed..."
      
      # Get the list of diagnostic settings that will be destroyed
      DIAG_SETTINGS=$(terraform state list 2>/dev/null | grep 'azurerm_monitor_diagnostic_setting.diagnostic_setting_logs' || echo "")
      
      if [ -z "$DIAG_SETTINGS" ]; then
        echo "✓ No diagnostic settings found in state - no locks to check"
        exit 0
      fi
      
      LOCK_REMOVED=false
      
      # For each diagnostic setting, extract the target resource ID and check for locks
      echo "$DIAG_SETTINGS" | while read DIAG_SETTING_KEY; do
        if [ -n "$DIAG_SETTING_KEY" ]; then
          # Get the target resource ID from the diagnostic setting
          TARGET_RESOURCE_ID=$(terraform state show "$DIAG_SETTING_KEY" 2>/dev/null | grep 'target_resource_id' | head -1 | awk '{print $3}' | tr -d '"' || echo "")
          
          if [ -n "$TARGET_RESOURCE_ID" ]; then
            echo ""
            echo "Checking locks for resource: $TARGET_RESOURCE_ID"
            
            # Extract resource type, name, and resource group from the ID
            RESOURCE_TYPE=$(echo "$TARGET_RESOURCE_ID" | awk -F'/providers/' '{print $2}' | awk -F'/' '{print $1"/"$2}')
            RESOURCE_NAME=$(echo "$TARGET_RESOURCE_ID" | awk -F'/' '{print $NF}')
            RESOURCE_GROUP=$(echo "$TARGET_RESOURCE_ID" | awk -F'/resourceGroups/' '{print $2}' | awk -F'/' '{print $1}')
            
            if [ -n "$RESOURCE_GROUP" ] && [ -n "$RESOURCE_NAME" ] && [ -n "$RESOURCE_TYPE" ]; then
              # Check for locks on this specific resource
              RESOURCE_LOCKS=$(az lock list \
                --resource-group "$RESOURCE_GROUP" \
                --resource-name "$RESOURCE_NAME" \
                --resource-type "$RESOURCE_TYPE" \
                --query "[].{name:name, id:id, level:level}" \
                -o json 2>/dev/null || echo "[]")
              
              if [ "$RESOURCE_LOCKS" != "[]" ] && [ -n "$RESOURCE_LOCKS" ]; then
                echo "  ⚠️  Found locks on this resource:"
                echo "$RESOURCE_LOCKS" | jq -r '.[] | "    - \(.name) (\(.level))"'
                
                # Remove each lock
                echo "$RESOURCE_LOCKS" | jq -r '.[].id' | while read LOCK_ID; do
                  if [ -n "$LOCK_ID" ]; then
                    LOCK_NAME=$(echo "$RESOURCE_LOCKS" | jq -r ".[] | select(.id==\"$LOCK_ID\") | .name")
                    echo "    → Removing lock: $LOCK_NAME"
                    az lock delete --ids "$LOCK_ID" 2>/dev/null && LOCK_REMOVED=true || echo "      ⚠️  Failed to remove lock (may lack permissions)"
                  fi
                done
              else
                echo "  ✓ No locks found on this resource"
              fi
              
              # Also check for locks at the resource group level
              RG_LOCKS=$(az lock list \
                --resource-group "$RESOURCE_GROUP" \
                --query "[?contains(id, '/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Authorization/locks')].{name:name, id:id, level:level}" \
                -o json 2>/dev/null || echo "[]")
              
              if [ "$RG_LOCKS" != "[]" ] && [ -n "$RG_LOCKS" ]; then
                echo "  ⚠️  Found locks at resource group level ($RESOURCE_GROUP):"
                echo "$RG_LOCKS" | jq -r '.[] | "    - \(.name) (\(.level))"'
                echo "    → These RG-level locks may also prevent resource deletion"
                
                # Remove RG-level locks
                echo "$RG_LOCKS" | jq -r '.[].id' | while read LOCK_ID; do
                  if [ -n "$LOCK_ID" ]; then
                    LOCK_NAME=$(echo "$RG_LOCKS" | jq -r ".[] | select(.id==\"$LOCK_ID\") | .name")
                    echo "    → Removing RG lock: $LOCK_NAME"
                    az lock delete --ids "$LOCK_ID" 2>/dev/null && LOCK_REMOVED=true || echo "      ⚠️  Failed to remove lock (may lack permissions)"
                  fi
                done
              fi
            fi
          fi
        fi
      done
      
      echo ""
      echo "==================== Lock Check Complete ===================="
      echo "✓ Lock removal process completed"
      echo "If you see permission warnings above, you may need Owner or"
      echo "User Access Administrator role to remove certain locks."
      echo ""
    SCRIPT
  }
}
