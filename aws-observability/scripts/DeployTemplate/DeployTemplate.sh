#!/bin/sh

# AWS CLI Configuration. Provide the Region and Profile where the CloudFormation Template needs to be deployed.
export AWS_REGION=$1
export AWS_PROFILE=$2

# Env Name. Provide Input parameter for env name.
export ENV_NAME=$3
if [ ! "${ENV_NAME}" ];then
   export ENV_NAME="default"
fi

# Provide an Stack Name which will be shown in AWS. Change the Default name if required.
export CF_STACK_NAME="SumoLogic-Aws-Observability-${AWS_REGION}"

# For parameters, please update the parameters.json file placed in the same folder.
# Visit - https://help.sumologic.com/Observability_Solution/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#configuration-prompts-and-input
export parameters_path=parameters-${ENV_NAME}.json

# Downloading the template to local for use. Remove if the template with same name if already present.
rm sumologic_observability_template.yaml
aws s3 cp s3://sumologic-appdev-aws-sam-apps/aws-observability-versions/v2.11.0/sumologic_observability.master.template.yaml sumologic_observability_template.yaml

# Deploy the template. If the Stack name already exist, stack will be updated else created.
aws cloudformation deploy --profile ${AWS_PROFILE} --region ${AWS_REGION} \
  --template-file sumologic_observability_template.yaml \
  --stack-name ${CF_STACK_NAME} \
  --parameter-overrides file://${parameters_path} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND