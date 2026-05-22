package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

// Deploy the resources using Terraform
func deployTerraform(t *testing.T, workingDir string, Variables map[string]interface{}, varsFile string) *terraform.ResourceCount {

	if varsFile == "" {
		varsFile = "vars.tfvars"
	}
	// The values to pass into the terraform CLI
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{

		// The path to where our Terraform code is located
		TerraformDir: workingDir,

		// Variables to pass to our Terraform code using -var options
		Vars: Variables,
		// VarFiles to pass vars.tfvars file
		VarFiles: []string{varsFile},

		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	})

	// Save the Terraform Options struct, instance name, and instance text so future test stages can use it
	test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	out := terraform.InitAndApply(t, terraformOptions)
	count := terraform.GetResourceCount(t, out)

	return count
}

// Destroy the resources using Terraform
func destroyTerraform(t *testing.T, workingDir string) {
	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)

	out, err := terraform.DestroyE(t, terraformOptions)
	if err != nil {
		// fmt.Println(err)
		terraform.DestroyE(t, terraformOptions)
	}
	fmt.Println(out)
}
