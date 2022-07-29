package test

import (
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"testing"
)

// Following Test cases are executed in sequence one after another.
// It takes around 20 mins to execute following 4 test scenerios.

// Main function
// Testing scenerio 1 - default scenerio
func TestAppModule1(t *testing.T) {
	// t.Parallel()

	// The values to pass into the terraform CLI
	TerraformDir := "../../examples/appmodule"
	props = loadPropertiesFile("../../examples/appmodule/main.auto.tfvars")
	Vars := map[string]interface{}{}

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		deployTerraform(t, TerraformDir, Vars)
	})

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		validateSumoLogicResources(t, TerraformDir)
	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
	})

}

// Testing scenerio 2 - Install in Admin Recom folder,share - true, override -  Monitor folder name, enable log + metric monitor
func TestAppModule2(t *testing.T) {
	// t.Parallel()

	Vars := map[string]interface{}{
		"sumologic_folder_installation_location": "Admin Recommended Folder",
		"sumologic_folder_share_with_org":        "true",
		"monitors_folder":                        "AWS Monitors Test2",
		"alb_monitors":                           "false",
		"ec2metrics_monitors":                    "false",
	}

	// The values to pass into the terraform CLI
	// rootFolder := ".."
	// terraformFolderRelativeToRoot := "examples/appmodule"
	// // Copy the terraform folder to a temp folder
	// TerraformDir := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)
	TerraformDir := "../../examples/appmodule"
	props = loadPropertiesFile("../../examples/appmodule/main.auto.tfvars")

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		deployTerraform(t, TerraformDir, Vars)
	})

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		validateSumoLogicResources(t, TerraformDir)
	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
	})
}

// Testing scenerio 3 - Install in Personal folder, share is false, override - App folder, enable log and metric monitor
func TestAppModule3(t *testing.T) {
	// t.Parallel()

	Vars := map[string]interface{}{
		"sumologic_folder_share_with_org": "false",
		"apps_folder":                     "AWS Observability Test3",
		"elasticache_monitors":            "false",
	}

	// The values to pass into the terraform CLI
	TerraformDir := "../../examples/appmodule"
	props = loadPropertiesFile("../../examples/appmodule/main.auto.tfvars")

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		deployTerraform(t, TerraformDir, Vars)
	})

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		validateSumoLogicResources(t, TerraformDir)
	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
	})
}

// Testing scenerio 4 - Install in Admin Recom folder,share - false, override - App folder name, Monitor folder name, enable metric monitor
func TestAppModule4(t *testing.T) {
	// t.Parallel()

	Vars := map[string]interface{}{
		"sumologic_folder_installation_location": "Admin Recommended Folder",
		"sumologic_folder_share_with_org":        "false",
		"apps_folder":                            "AWS Observability Test4",
		"monitors_folder":                        "AWS Monitors Test4",
		"ecs_monitors":                           "false",
	}

	// The values to pass into the terraform CLI
	TerraformDir := "../../examples/appmodule"
	props = loadPropertiesFile("../../examples/appmodule/main.auto.tfvars")

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		deployTerraform(t, TerraformDir, Vars)
	})

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		validateSumoLogicResources(t, TerraformDir)
	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
	})
}
