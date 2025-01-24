#!/bin/bash

# Base directory (current directory)
BASE_DIR=$(pwd)

# Directories to skip
SKIP_DIRS=("test" "cloudformation-module")

# Function to traverse directories
traverse_directories() {
  local dir=$1

  # Check if README.md exists in the current directory
  if [[ -f "$dir/README.md" ]]; then
    echo "Executing 'terraform-docs markdown .' in $dir"
    # Navigate to the directory and run the command
    (cd "$dir" && terraform-docs markdown . > README.md)
  fi

  # Traverse through subdirectories
  for subdir in "$dir"/*/; do
    # Ensure it's a directory
    if [[ -d "$subdir" ]]; then
      # Extract the directory name
      local subdir_name=$(basename "$subdir")
      # Skip the directories in the SKIP_DIRS array
      if [[ ! " ${SKIP_DIRS[@]} " =~ " ${subdir_name} " ]]; then
        traverse_directories "$subdir"
      fi
    fi
  done
}

# Start traversal from the base directory
traverse_directories "$BASE_DIR"
