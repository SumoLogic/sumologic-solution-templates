#!/bin/sh

echo "Start S3 upload Script....."

export AWS_PROFILE="prod"

bucket_name=app-json-store
match_case="AWS"

yourfilenames=`ls ../json/*.json`
for app_file in ${yourfilenames}
do
	if [[ "${app_file}" == *"${match_case}"* ]]; then
		if [[ ${AWS_PROFILE} == 'default' ]]
		then
    	    aws s3 cp ${app_file} s3://${bucket_name}/ --acl public-read --profile ${AWS_PROFILE}
    	    echo "Uploaded File Name -> ${app_file} to bucket -> ${bucket_name}"
    	fi
    fi
done

echo "End S3 upload Script....."