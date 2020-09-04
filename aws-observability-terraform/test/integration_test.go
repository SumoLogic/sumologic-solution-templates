package test

import (
    "fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	aws_cf "github.com/aws/aws-sdk-go/service/cloudformation"
)

func CloudFormationTest(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",
		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the cloudformation stack ID
	cloudformation_stack_id := terraform.Output(t, terraformOptions, "cloudformation_stack_id")
    fmt.Println("CloudFormation Stack ID " + cloudformation_stack_id)
    // Validate 200 Ok response from CF.
    out := GetCloudFormationTemplate(t, "us-east-1", cloudformation_stack_id)
    fmt.Println(out)
}

// GetCloudFormationTemplate fetches the Cloudformation stack. This will fail the test if there are any errors
func GetCloudFormationTemplate(t *testing.T, region string, stackId string) *aws_cf.DescribeStacksOutput {
	out, err := GetCloudFormationTemplateE(t, region, stackId)
	if err != nil {
		t.Fatal(err)
	}
	return out
}

// GetDynamoDbTableTagsE fetches resource tags of a specified dynamoDB table.
func GetCloudFormationTemplateE(t *testing.T, region string, stackId string) (*aws_cf.DescribeStacksOutput, error) {
	out, err := NewCFClient(t, region).DescribeStacks(&aws_cf.DescribeStacksInput{
		StackName: aws.String(stackId),
	})
	if err != nil {
		return nil, err
	}
	return out, err
}

// NewCFClient allocates a new CF client
func NewCFClient(t *testing.T, Region string) *aws_cf.CloudFormation {
	client, err := NewCFClientE(t, Region)
	if err != nil {
		t.Fatal(err)
	}
	return client
}

// NewCFClientE allocates a new CF and possibly an error
func NewCFClientE(t *testing.T, Region string) (*aws_cf.CloudFormation, error) {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(Region),
	})
	if err != nil {
		return nil, err
	}

	return aws_cf.New(sess), nil
}