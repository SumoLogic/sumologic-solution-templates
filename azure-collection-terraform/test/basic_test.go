package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestBasicSyntax(t *testing.T) {
	terraformDir := "../"

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		NoColor:      true,
	}

	terraform.Validate(t, terraformOptions)
}
