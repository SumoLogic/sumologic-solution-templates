#!/usr/bin/env bash

export version="v2.0.18"

if [[ -f SumoLogicAWSObservabilityHelper.zip ]]; then
    rm SumoLogicAWSObservabilityHelper.zip
fi

if [[ -f SumoLogicAWSObservabilityHelper${version}.zip ]]; then
    rm SumoLogicAWSObservabilityHelper${version}.zip
fi

export AWS_PROFILE="personal"

aws s3 cp s3://appdevzipfiles-us-east-1/sumologic-aws-observability/apps/SumoLogicAWSObservabilityHelper/SumoLogicAWSObservabilityHelperv${version}.zip --profile ${AWS_PROFILE} --region us-east-1
