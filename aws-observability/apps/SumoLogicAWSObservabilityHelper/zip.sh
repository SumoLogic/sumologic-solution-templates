if [ -f SumoLogicAWSObservabilityHelper.zip ]; then
    rm SumoLogicAWSObservabilityHelper.zip
fi

export AWS_PROFILE="default"

export version="v2.0.0"

aws s3 cp s3://appdevstore/sumo_app_utils/${version}/sumo_app_utils.zip SumoLogicAWSObservabilityHelper.zip --profile ${AWS_PROFILE} --region us-east-1