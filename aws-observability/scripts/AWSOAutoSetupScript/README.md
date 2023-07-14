## Pre-Requisite
[AWS CLI](https://aws.amazon.com/cli/)

# AWS Observability Deployment using Script
## For installing on Mac and Linux
### Command
The `DeployAWSOPosix.sh` enables you to deploy the AWS Observability CloudFromation template using AWS CLI commands.
 
```
wget "https://raw.githubusercontent.com/SumoLogic/sumologic-solution-templates/master/aws-observability/scripts/AWSOAutoSetupScript/DeployAWSOPosix.sh"

chmod +x DeployAWSOPosix.sh

./DeployAWSOPosix.sh -i <SUMO_ACCESS_ID> -k <SUMO_ACCESS_KEY> -p <AWS_PROFILE> -r <AWS_REGION>
```

### Parameters
Provide the following details where you want to install AWS Observability Solution

| Parameter       | Alias | Mandatory | Default   | Description                                             |
|-----------------|-------|-----------|-----------|---------------------------------------------------------|
| SUMO_ACCESS_ID  | -i    | Yes       | <>        | Sumo Access Id from your respective Sumo Logic Account  |
| SUMO_ACCESS_KEY | -k    | Yes       | <>        | Sumo Access Key from your respective Sumo Logic Account |
| AWS_PROFILE     | -p    | No        | default   | User profile from AWS account which you want to observe |
| AWS_REGION      | -r    | No        | us-east-1 | AWS region which you want to observe                    |

<details>
<summary>Above command performs following actions</summary>
    <br>Downloading master template using wget command.</br>
    <br>Using chmod command to grant execute permission to shell script.</br>
    <br>Execute shell script for deploying the solution.</br>
</details>

## For installing on Windows through powershell
### Command
The `DeployAWSOWin.ps1` enables you to deploy the AWS Observability CloudFromation template using AWS CLI commands.
 
```
$uri="https://raw.githubusercontent.com/SumoLogic/sumologic-solution-templates/master/aws-observability/scripts/AWSOAutoSetupScript/DeployAWSOWin.ps1";$path=".\DeployAWSOWin.ps1";(New-Object System.Net.WebClient).DownloadFile($uri, $path);

.\DeployAWSOWin.ps1 -i <SUMO_ACCESS_ID> -k <SUMO_ACCESS_KEY> -p <AWS_PROFILE> -r <AWS_REGION>
```

### Parameters
Provide the following details where you want to install AWS Observability Solution

| Parameter       | Alias | Mandatory | Default   | Description                                             |
|-----------------|-------|-----------|-----------|---------------------------------------------------------|
| SUMO_ACCESS_ID  | -i    | Yes       | <>        | Sumo Access Id from your respective Sumo Logic Account  |
| SUMO_ACCESS_KEY | -k    | Yes       | <>        | Sumo Access Key from your respective Sumo Logic Account |
| AWS_PROFILE     | -p    | No        | default   | AWS account which you want to observe                   |
| AWS_REGION      | -r    | No        | us-east-1 | AWS region which you want to observe                    |

<details>
<summary>Above command performs following actions</summary>
    <br>Downloading master template using DownloadFile function.</br>
    <br>Execute powershell script for deploying the solution.</br>
</details>