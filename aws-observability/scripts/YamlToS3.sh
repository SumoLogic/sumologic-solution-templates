#!/bin/sh

echo "Start S3 upload Script....."

export AWS_PROFILE="prod"

declare -a regions=("us-east-2" "us-east-1" "us-west-1" "us-west-2" "ap-south-1" "ap-northeast-2" "ap-southeast-1" "ap-southeast-2" "ap-northeast-1" "ca-central-1" "eu-central-1" "eu-west-1" "eu-west-2" "eu-west-3" "eu-north-1s" "sa-east-1" "ap-east-1s" "af-south-1s" "eu-south-1" "me-south-1s" "me-central-1" "eu-central-2s" "ap-northeast-3s" "ap-southeast-3")

# Some buckets names have 's' or 'ss' in the region suffix. It is kept intentional as bucket names were not available.
# Buckets names which are intentional -
# 1. appdevzipfiles-eu-north-1s
# 2. appdevzipfiles-ap-east-1s
# 3. appdevzipfiles-af-south-1s
# 4. appdevzipfiles-me-south-1s
# 5. appdevzipfiles-eu-central-2ss
# 6. appdevzipfiles-ap-northeast-3s

cd ..\/

# Upload the ZIP file to bucket appdevzipfiles- in every region with the new version.
if [[ ${AWS_PROFILE} == 'default' ]]
then
  for region in "${regions[@]}"
  do
      bucket_name=appdevzipfiles-$region

      if [[ `echo ${region} | awk '{print substr($0,length,1)}'` == "s" ]]
      then
          export region=`echo "${region%?}"`
      fi

      aws s3 cp apps/SumoLogicAWSObservabilityHelper/ s3://${bucket_name}/sumologic-aws-observability/apps/SumoLogicAWSObservabilityHelper/ --recursive --include '*.zip' --exclude '*.sh' --region ${region} --acl public-read --profile ${AWS_PROFILE}

      echo "ZIP Upload complete for Region -> ${region} and Bucket Name -> ${bucket_name}"
  done
fi

# Upload Control Tower and Permission Check template to sumologic-appdev-aws-sam-apps bucket
export bucket_name=sumologic-appdev-aws-sam-apps

if [[ ${AWS_PROFILE} == 'default' ]]
then
    aws s3 cp apps/permissionchecker/permissioncheck.template.yaml s3://${bucket_name}/ --acl public-read --profile ${AWS_PROFILE}
    echo "Upload complete for Permission check Template to Bucket Name -> ${bucket_name}"

    aws s3 cp apps/controltower/controltower.template.yaml s3://${bucket_name}/ --acl public-read --profile ${AWS_PROFILE}
    echo "Upload complete for Control Tower Template to Bucket Name -> ${bucket_name}"
fi

# Upload all templates to sumologic-appdev-aws-sam-apps bucket with version information.
if [[ ${AWS_PROFILE} == 'default' ]]
then
    export version=v2.9.0

    aws s3 cp apps/ s3://${bucket_name}/aws-observability-versions/${version}/ --recursive --include "*.template.yaml" --exclude '*.zip' --exclude '*.sh' --exclude 'apps/*/test/*' --exclude '*/test/*' --acl public-read --profile ${AWS_PROFILE}

    aws s3 cp templates/sumologic_observability.master.template.yaml s3://${bucket_name}/aws-observability-versions/${version}/ --acl public-read --profile ${AWS_PROFILE}

    echo "Upload complete for Master and Nested Template to Bucket Name -> ${bucket_name}"
fi

echo "End S3 upload Script....."