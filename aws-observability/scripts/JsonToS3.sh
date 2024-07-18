#!/bin/sh

echo "Start S3 upload Script....."

export AWS_PROFILE="prod"

export bucket_name=sumologic-appdev-aws-sam-apps
export version=v2.9.0
export match_case="App"

if [[ ${AWS_PROFILE} == 'default' ]]
then
  your_file_names=`ls ../json/*.json`
  for app_file in ${your_file_names}
  do
	  if [[ "${app_file}" == *"${match_case}"* ]]; then

    	aws s3 cp ${app_file} s3://${bucket_name}/aws-observability-versions/${version}/appjson/ --acl public-read --profile ${AWS_PROFILE}

    	echo "Uploaded File Name -> ${app_file} to bucket -> ${bucket_name}"

    fi
  done
fi

echo "End S3 upload Script....."