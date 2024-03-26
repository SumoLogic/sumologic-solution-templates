#!/usr/bin/env bash

export version="v2.0.18"

export AWS_PROFILE="prod"


aws s3 cp SumoLogicAWSObservabilityHelper${version}.zip  s3://appdevzipfiles-eu-north-1s/sumologic-aws-observability/apps/SumoLogicAWSObservabilityHelper/SumoLogicAWSObservabilityHelper${version}.zip --profile ${AWS_PROFILE} --region eu-north-1

aws s3 cp SumoLogicAWSObservabilityHelper${version}.zip  s3://appdevzipfiles-ap-southeast-1/sumologic-aws-observability/apps/SumoLogicAWSObservabilityHelper/SumoLogicAWSObservabilityHelper${version}.zip --profile ${AWS_PROFILE} --region ap-southeast-1
