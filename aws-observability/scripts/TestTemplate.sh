#!/bin/sh

export folder_name=rootcause
export template_version="v2.9.0"
export template_bucket="sumologic-appdev-aws-sam-apps"
export lambda_arn="arn:aws:lambda:ap-south-1:668508221233:function:LambdaFucntion-LambdaHelper-1C1GGLRYPWBB0"

sumocfntester -f ../apps/${folder_name}/test/TestTemplate.yaml