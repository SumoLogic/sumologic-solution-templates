# AWS Observability Deployment using Script
The `DeployTemplate.sh` enables you to deploy the AWS Observability v3.0.0 CloudFormation template using AWS CLI commands.

## Pre-Requisite
[AWS CLI](https://aws.amazon.com/cli/)

## Uses
Script takes three inputs:
1. **AWS_REGION** — AWS region where you would like to deploy the CloudFormation template.
2. **AWS_PROFILE** — AWS CLI profile pointing to the account where you want to deploy.
3. **ENVIRONMENT** — selects the parameters JSON file. Naming convention: `parameters-{environment}.json`. Keep files in the same folder.

The script prompts for your **Sumo Logic Access Key** interactively (input is hidden). The key is never stored in the parameters file.

## Command
Below is an example with AWS Region = us-east-1, AWS Profile = default, and Environment = default.

```
bash DeployTemplate.sh us-east-1 default default
```

## Parameters File
Fill in the required values in `parameters-{environment}.json` before running the script.

| Parameter | Description |
|-----------|-------------|
| `Section1aSumoLogicDeployment` | Sumo Logic deployment (au, ca, ch, de, eu, esc, fed, jp, kr, us1, us2) |
| `Section1bSumoLogicAccessID` | Sumo Logic Access ID |
| `Section1dSumoLogicOrganizationId` | Sumo Logic Organization ID |
| `Section1eSumoLogicResourceRemoveOnDeleteStack` | Delete Sumo Logic resources when stack is deleted (true/false) |
| `Section1fSumoLogicSendTelemetry` | Send telemetry to Sumo Logic (true/false) |
| `Section2aAccountAlias` | Alias for AWS account identification in Sumo Logic |
| `Section2bAccountAliasMappingS3URL` | S3 URL of a CSV file mapping AWS Account IDs to aliases (optional) |

> **Note:** `Section1cSumoLogicAccessKey` is intentionally absent from the parameters file. The script reads it interactively at runtime so it is never written to disk.

## Environment
Create multiple parameter JSON files to target different AWS regions and accounts. Pass the environment name as the third argument.

Follow the naming convention `parameters-{environment}.json`. Examples:

- `parameters-dev.json` → `bash DeployTemplate.sh us-east-1 default dev`
- `parameters-prod.json` → `bash DeployTemplate.sh us-east-1 default prod`
