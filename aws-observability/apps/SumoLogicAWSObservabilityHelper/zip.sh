#!/usr/bin/env bash

export version="v2.0.1"

if [[ -f SumoLogicAWSObservabilityHelper.zip ]]; then
    rm SumoLogicAWSObservabilityHelper.zip
fi

if [[ -f SumoLogicAWSObservabilityHelper${version}.zip ]]; then
    rm SumoLogicAWSObservabilityHelper${version}.zip
fi

export AWS_PROFILE="personal"

aws s3 cp s3://sumologiclambdahelper-us-east-1/sumo_app_utils/${version}/sumo_app_utils.zip SumoLogicAWShObservabilityHelper${version}.zip --profile ${AWS_PROFILE} --region us-east-1