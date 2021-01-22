package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TODO: Replace with command line arguements

var accountAlias = fmt.Sprintf("infra-test-%s", strings.ToLower(random.UniqueId()))
var sumologicAccessKey = ""
var sumologicEnvironment = "us2"
var sumologicAccessID = ""
var sumoLogicOrganizationId = ""

func CommonResources() {}

func AppInstall() {}

func InventorySource() {
}

func XRaySource() {
}

func TestRootAll(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "true",
			"manage_cloudwatch_metrics_source": "true",
			"manage_alb_logs_source":           "true",
			"manage_alb_s3_bucket":             "true",
			"manage_cloudtrail_bucket":         "true",
			"manage_cloudwatch_logs_source":    "true",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

}

func TestAppOnly(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "true",
			"manage_cloudwatch_metrics_source": "true",
			"manage_alb_logs_source":           "true",
			"manage_alb_s3_bucket":             "true",
			"manage_cloudtrail_bucket":         "true",
			"manage_cloudwatch_logs_source":    "true",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

}

func TestInventorySourceOnly(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "true",
			"manage_cloudwatch_metrics_source": "true",
			"manage_alb_logs_source":           "true",
			"manage_alb_s3_bucket":             "true",
			"manage_cloudtrail_bucket":         "true",
			"manage_cloudwatch_logs_source":    "true",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

}

func TestXraySourceOnly(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "true",
			"manage_cloudwatch_metrics_source": "true",
			"manage_alb_logs_source":           "true",
			"manage_alb_s3_bucket":             "true",
			"manage_cloudtrail_bucket":         "true",
			"manage_cloudwatch_logs_source":    "true",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

}

func TestSourcesOnly(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "true",
			"manage_cloudwatch_metrics_source": "true",
			"manage_alb_logs_source":           "true",
			"manage_alb_s3_bucket":             "true",
			"manage_cloudtrail_bucket":         "true",
			"manage_cloudwatch_logs_source":    "true",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

}
