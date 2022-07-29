package test

import (
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudformation"
	"github.com/aws/aws-sdk-go/service/cloudtrail"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
	"github.com/aws/aws-sdk-go/service/firehose"
	"github.com/aws/aws-sdk-go/service/iam"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

var (
	s3session         *s3.S3
	SNSsession        *sns.SNS
	IAMsession        *iam.IAM
	lambdasession     *lambda.Lambda
	cfSession         *cloudformation.CloudFormation
	kfSession         *firehose.Firehose
	cwSession         *cloudwatch.CloudWatch
	cloudTrailsession *cloudtrail.CloudTrail
)

const (
	REGION = "us-east-1"
)

func init() {
	s3session = s3.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(REGION),
	})))
	SNSsession = sns.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(REGION),
	})))
	IAMsession = iam.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(REGION),
	})))
	cloudTrailsession = cloudtrail.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(REGION),
	})))
	lambdasession = lambda.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(REGION),
	})))
	cfSession = cloudformation.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(REGION),
	})))
	kfSession = firehose.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(REGION),
	})))
	cwSession = cloudwatch.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(REGION),
	})))
}

func validateS3Bucket(t *testing.T, terraformOptions *terraform.Options, bucketName string) (resp *s3.GetBucketAclOutput) {
	resp, err := s3session.GetBucketAcl(&s3.GetBucketAclInput{
		Bucket: aws.String(bucketName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateSNSTopic(t *testing.T, terraformOptions *terraform.Options, topicName string) (resp *sns.GetTopicAttributesOutput) {
	resp, err := SNSsession.GetTopicAttributes(&sns.GetTopicAttributesInput{
		TopicArn: aws.String(topicName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateSNSsub(t *testing.T, terraformOptions *terraform.Options, subscriptionARN string) (resp *sns.GetSubscriptionAttributesOutput) {
	resp, err := SNSsession.GetSubscriptionAttributes(&sns.GetSubscriptionAttributesInput{
		SubscriptionArn: aws.String(subscriptionARN),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateIAMRole(t *testing.T, terraformOptions *terraform.Options, roleName string) (resp *iam.GetRoleOutput) {
	resp, err := IAMsession.GetRole(&iam.GetRoleInput{
		RoleName: aws.String(roleName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateCloudTrail(t *testing.T, terraformOptions *terraform.Options, trailName string) (resp *cloudtrail.GetTrailOutput) {
	resp, err := cloudTrailsession.GetTrail(&cloudtrail.GetTrailInput{
		Name: aws.String(trailName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateLambda(t *testing.T, terraformOptions *terraform.Options, functionName string) (resp *lambda.GetFunctionOutput) {
	resp, err := lambdasession.GetFunction(&lambda.GetFunctionInput{
		FunctionName: aws.String(functionName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateCFStack(t *testing.T, terraformOptions *terraform.Options, stackName string) (resp *cloudformation.DescribeStacksOutput) {
	resp, err := cfSession.DescribeStacks(&cloudformation.DescribeStacksInput{
		StackName: aws.String(stackName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateKFstream(t *testing.T, terraformOptions *terraform.Options, streamName string) (resp *firehose.DescribeDeliveryStreamOutput) {
	resp, err := kfSession.DescribeDeliveryStream(&firehose.DescribeDeliveryStreamInput{
		DeliveryStreamName: aws.String(streamName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}

func validateCWmetricstream(t *testing.T, terraformOptions *terraform.Options, metricStreamName string) (resp *cloudwatch.GetMetricStreamOutput) {
	resp, err := cwSession.GetMetricStream(&cloudwatch.GetMetricStreamInput{
		Name: aws.String(metricStreamName),
	})
	if err != nil {
		panic(err)
	}
	return resp
}
