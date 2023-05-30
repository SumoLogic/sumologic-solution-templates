## Pre-Requisite
[AWS CLI](https://aws.amazon.com/cli/)

# For installing on Mac and Linux, here are the instructions
# AWS Observability Deployment using Script
The `DeployAWSOPosix.sh` enables you to deploy the AWS Observability CloudFromation template using AWS CLI commands.



## Parameters
Script takes two inputs
1. SUMO ACCESS ID - Provide the Sumo Access Id from your respective Sumo Logic Account where you want to install AWS Observability Solution
2. SUMO ACCESS KEY - Provide the Sumo Access Key from your respective Sumo Logic Account where you want to install AWS Observability Solution

AWS_PROFILE can be set as environment variable from the Command Line before executing the sh file. If it is not set, default aws profile will be picked from the local machine.

## Command
Below is an example to run the sh file with respective parameters
 
`./DeployAWSOPosix.sh <SUMO_ACCESS_ID> <SUMO_ACCESS_KEY>`





# For installing on Windows through powershell, here are the instructions
# AWS Observability Deployment using Script
The `DeployAWSOWin.ps1` enables you to deploy the AWS Observability CloudFromation template using AWS CLI commands.

## Parameters
Script takes two inputs
1. SUMO ACCESS ID - Provide the Sumo Access Id from your respective Sumo Logic Account where you want to install AWS Observability Solution
2. SUMO ACCESS KEY - Provide the Sumo Access Key from your respective Sumo Logic Account where you want to install AWS Observability Solution

AWS_PROFILE can be set as environment variable from the Command Line before executing the ps1 file. If it is not set, default aws profile will be picked from the local machine.

## Command
Below is an example to run the ps1 file with respective parameters
 
`.\DeployAWSOWin.ps1 <SUMO_ACCESS_ID> <SUMO_ACCESS_KEY>`
