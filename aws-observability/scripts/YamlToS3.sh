#!/bin/sh

echo "Start S3 upload Script....."

export AWS_PROFILE="personal"

declare -a regions=("us-west-2")

cd ..\/

for region in "${regions[@]}"
do
    bucket_name=cf-templates-1qpf3unpuo1hw-$region

    if [[ `echo ${region} | awk '{print substr($0,length,1)}'` == "s" ]]
    then
        export region=`echo "${region%?}"`
    fi

    aws s3 cp . s3://$bucket_name/sumologic-aws-observability/ --region ${region} --recursive --exclude '*.sh' --exclude 'apps/*/test/*' --exclude '*/test/*' --exclude '*.json' --exclude '.git/*' --exclude '.idea/*' --acl public-read --profile ${AWS_PROFILE}

    echo "Upload complete for Region -> $region and Bucket Name -> $bucket_name"
done

echo "End S3 upload Script....."