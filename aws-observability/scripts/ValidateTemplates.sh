#!/bin/sh

declare -a apps=('alb' 'anomaly' 'apigateway' 'autoenable' 'AutoTagAWSResources' 'common' 'dynamodb' 'ec2metrics' 'hostmetricsfields' 'lambda' 'rds' 'master')

cd ..\/

for app in "${apps[@]}"
do

    if [[ "${app}" != "master" ]]
    then
        path=apps/${app}
    else
        path=templates
    fi
    output=`cfn-lint ./${path}/*.yaml`
    echo "Validation complete for File -> app with Output as ${output}"

    output=`cfn_nag ./${path}/*.yaml`
    echo "Security Validation complete for File -> app with Output as \n ${output}"
done