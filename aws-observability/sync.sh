#!/bin/bash

# Source directory for CloudFormation (CF) templates
MASTER_TEMPLATE=./templates/sumologic_observability.master.template.yaml
APPS_TEMPLATES_DIR=./apps
APPS_JSON_DIR=./json

# Bucket name
CF_VERSION=v2.9.0
BUCKET_REGION=us-east-1
BUCKET=sumologic-appdev-aws-sam-apps
S3_KEY_PREFIX=aws-observability-versions/${CF_VERSION}

# S3 Location
S3_TEMPLATES=s3://${BUCKET}/${S3_KEY_PREFIX}/
S3_JSON_DIR=s3://${BUCKET}/${S3_KEY_PREFIX}/appjson

# Sync options (Add --exclude '*.zip' if you don't want to upload lambda)
AWS_PROFILE=prod

if [[ " $@ " =~ " --dryrun " ]]; then
    isdryrun="--dryrun"
else
    isdryrun=""
fi

# sync should be first and then cp. DO NOT CHANGE ORDER
echo "Copying child templates from ${APPS_TEMPLATES_DIR} to Bucket ${S3_TEMPLATES} in ${BUCKET_REGION}"
aws s3 sync ${APPS_TEMPLATES_DIR}/ ${S3_TEMPLATES} --delete --include '*.yaml' --exclude '*.DS_Store'  --exclude '*/test/*' --exclude 'SumoLogicAWSObservabilityHelper/*' --acl public-read ${isdryrun} --profile ${AWS_PROFILE} --region ${BUCKET_REGION}
echo "Copying json folder ${APPS_JSON_DIR} to Bucket ${S3_JSON_DIR} in ${BUCKET_REGION}"
aws s3 cp --recursive ${APPS_JSON_DIR} ${S3_JSON_DIR} --acl public-read ${isdryrun} --profile ${AWS_PROFILE} --region ${BUCKET_REGION}
echo "Copying master template ${MASTER_TEMPLATE} to Bucket ${S3_TEMPLATES} in ${BUCKET_REGION}"
aws s3 cp ${MASTER_TEMPLATE} ${S3_TEMPLATES} --acl public-read ${isdryrun} --profile ${AWS_PROFILE} --region ${BUCKET_REGION}
