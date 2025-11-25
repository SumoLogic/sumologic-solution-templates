package test

import (
	"path/filepath"
	"testing"
)

// TestWhitelistIPsValidation tests the whitelist_ips variable validation
func TestWhitelistIPsValidation(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "ValidEmptyWhitelist",
			tfvarsFile:  filepath.Join("test", fixturesDir, "whitelist-ips-empty.tfvars"),
			expectError: false,
			description: "Empty whitelist_ips should pass validation",
		},
		{
			name:        "ValidSingleIP",
			tfvarsFile:  filepath.Join("test", fixturesDir, "whitelist-ips-single.tfvars"),
			expectError: false,
			description: "Single valid IP address should pass validation",
		},
		{
			name:        "ValidCIDR",
			tfvarsFile:  filepath.Join("test", fixturesDir, "whitelist-ips-cidr.tfvars"),
			expectError: false,
			description: "Valid CIDR block should pass validation",
		},
		{
			name:        "ValidMultiple",
			tfvarsFile:  filepath.Join("test", fixturesDir, "whitelist-ips-multiple.tfvars"),
			expectError: false,
			description: "Multiple valid IPs and CIDR blocks should pass validation",
		},
		{
			name:        "InvalidIPFormat",
			tfvarsFile:  filepath.Join("test", fixturesDir, "whitelist-ips-invalid-format.tfvars"),
			expectError: true,
			description: "Invalid IP format should fail validation",
		},
		{
			name:        "InvalidCIDR",
			tfvarsFile:  filepath.Join("test", fixturesDir, "whitelist-ips-invalid-cidr.tfvars"),
			expectError: true,
			description: "Invalid CIDR format should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runValidationTest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
		})
	}
}
