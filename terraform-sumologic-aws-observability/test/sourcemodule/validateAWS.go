package test

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudformation"
	"github.com/aws/aws-sdk-go-v2/service/cloudtrail"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	"github.com/aws/aws-sdk-go-v2/service/firehose"
	"github.com/aws/aws-sdk-go-v2/service/iam"
	"github.com/aws/aws-sdk-go-v2/service/lambda"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"log"
	"testing"
)

var (
	s3Client         *s3.Client
	snsClient        *sns.Client
	iamClient        *iam.Client
	lambdaClient     *lambda.Client
	cfClient         *cloudformation.Client
	firehoseClient   *firehose.Client
	cloudwatchClient *cloudwatch.Client
	cloudtrailClient *cloudtrail.Client
)

const (
	REGION = "us-east-1"
)

func init() {
	// Load default config with custom region
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(REGION))
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}
	s3Client = s3.NewFromConfig(cfg)
	snsClient = sns.NewFromConfig(cfg)
	iamClient = iam.NewFromConfig(cfg)
	lambdaClient = lambda.NewFromConfig(cfg)
	cfClient = cloudformation.NewFromConfig(cfg)
	firehoseClient = firehose.NewFromConfig(cfg)
	cloudwatchClient = cloudwatch.NewFromConfig(cfg)
	cloudtrailClient = cloudtrail.NewFromConfig(cfg)
}

func validateS3Bucket(t *testing.T, terraformOptions *terraform.Options, bucketName string) (resp *s3.GetBucketAclOutput) {
	resp, err := s3Client.GetBucketAcl(context.TODO(), &s3.GetBucketAclInput{
		Bucket: aws.String(bucketName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateSNSTopic(t *testing.T, terraformOptions *terraform.Options, topicName string) (resp *sns.GetTopicAttributesOutput) {
	resp, err := snsClient.GetTopicAttributes(context.TODO(), &sns.GetTopicAttributesInput{
		TopicArn: aws.String(topicName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateSNSsub(t *testing.T, terraformOptions *terraform.Options, subscriptionARN string) (resp *sns.GetSubscriptionAttributesOutput) {
	resp, err := snsClient.GetSubscriptionAttributes(context.TODO(), &sns.GetSubscriptionAttributesInput{
		SubscriptionArn: aws.String(subscriptionARN),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateIAMRole(t *testing.T, terraformOptions *terraform.Options, roleName string) (resp *iam.GetRoleOutput) {
	resp, err := iamClient.GetRole(context.TODO(), &iam.GetRoleInput{
		RoleName: aws.String(roleName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateCloudTrail(t *testing.T, terraformOptions *terraform.Options, trailName string) (resp *cloudtrail.GetTrailOutput) {
	resp, err := cloudtrailClient.GetTrail(context.TODO(), &cloudtrail.GetTrailInput{
		Name: aws.String(trailName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateLambda(t *testing.T, terraformOptions *terraform.Options, functionName string) (resp *lambda.GetFunctionOutput) {
	resp, err := lambdaClient.GetFunction(context.TODO(), &lambda.GetFunctionInput{
		FunctionName: aws.String(functionName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateCFStack(t *testing.T, terraformOptions *terraform.Options, stackName string) (resp *cloudformation.DescribeStacksOutput) {
	resp, err := cfClient.DescribeStacks(context.TODO(), &cloudformation.DescribeStacksInput{
		StackName: aws.String(stackName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateKFstream(t *testing.T, terraformOptions *terraform.Options, streamName string) (resp *firehose.DescribeDeliveryStreamOutput) {
	resp, err := firehoseClient.DescribeDeliveryStream(context.TODO(), &firehose.DescribeDeliveryStreamInput{
		DeliveryStreamName: aws.String(streamName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateCWmetricstream(t *testing.T, terraformOptions *terraform.Options, metricStreamName string) (resp *cloudwatch.GetMetricStreamOutput) {
	resp, err := cloudwatchClient.GetMetricStream(context.TODO(), &cloudwatch.GetMetricStreamInput{
		Name: aws.String(metricStreamName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}
