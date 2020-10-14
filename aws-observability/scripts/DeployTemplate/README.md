# AWS Observability Deployment using Script
The `DeployTemplate.sh` enables you to deploy the AWS Observability CloudFromation template using AWS CLI commands.

## Pre-Requisite
[AWS CLI](https://aws.amazon.com/cli/)

## Uses
Script takes three inputs
1. AWS REGION - provide an aws region where you would like to install the CloudFormation template.
2. AWS PROFILE - provide an aws profile(from your aws cli configuration) which points to an AWS account where you would like to deploy the CloudFormation template.
3. ENVIRONMENT - provide an environment value which will pick up the parameters json file. Naming convention for parameters json file is `parameters-{environment}.json`. Keep the files in the same folder.

## Command
Below is an example to run the sh file with AWS Region = us-east-1, AWS Profile = Default and Environment = Default.
 
`sh DeployTemplate.sh us-east-1 default default`

## Environment
Create multiple parameters JSONs files to identify different AWS regions and accounts. Pass those environment values as inputs to `sh` file. 

Follow Naming convention for environment files as `parameters-{environment}.json`. Below are some examples -

- parameters-dev.json - `sh DeployTemplate.sh us-east-1 default dev ` 
- parameters-prod.json - `sh DeployTemplate.sh us-east-1 default prod `
