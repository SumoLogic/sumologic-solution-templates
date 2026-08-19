# Inputs to the script- Mandatory - SUMO_ACCESS_ID, Optional - AWS_PROFILE and AWS_REGION
param(
     [Parameter(Mandatory,HelpMessage="Enter Sumo Logic Access ID.")]
	 [Alias('i')]
     [string]$SUMO_ACCESS_ID,

     [Parameter(HelpMessage="Enter AWS Profile.")]
	 [Alias('p')]
     [string]$AWS_PROFILE,

	 [Parameter(HelpMessage="Enter AWS Region.")]
	 [Alias('r')]
     [string]$AWS_REGION
 )

$secureKey = Read-Host -Prompt "Enter Sumo Logic Access Key" -AsSecureString
$SUMO_ACCESS_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
)
if (-not $SUMO_ACCESS_KEY) {
    echo "Access key cannot be empty."
    Exit 1
}

# If profile(-p) is empty set default profile
if(-not $AWS_PROFILE){
	echo "Setting AWS_PROFILE as default"
	$AWS_PROFILE="default"
}

# If region(-r) is empty set us-east-1 region
if(-not $AWS_REGION){
	echo "Setting AWS_REGION as us-east-1"
	$AWS_REGION="us-east-1"
}


try{
$awsCheck=aws --version
}
catch{
	echo "aws cli not installed. Please install aws cli and rerun the AWS Observability script"
	Exit
}
$now=Get-Date
echo "AWS Observability Script initiated at : $now"

#identify sumo deployment associated with sumo accessId and accessKey
$masterTemplateURL="https://sumologic-appdev-aws-sam-apps.s3.amazonaws.com/aws-observability-versions/v3.0.0/templates/sumologic_observability.master.template.yaml"
$apiUrl="https://api.sumologic.com"
$deployment="us1"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "$SUMO_ACCESS_ID","$SUMO_ACCESS_KEY")))

try{
$result = Invoke-WebRequest -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}  -Uri "$apiUrl/api/v1/collectors/"
}
catch {
	$hostvar = $_.Exception.Response.ResponseUri.Host
	$deployment=$hostvar.Split(".")[1]
	$apiUrl="https://api.$deployment.sumologic.com"
}

#identify sumo OrgId associated with sumo accessId and accessKey
try{
$response=Invoke-WebRequest -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}  -Uri "$apiUrl/api/v1/account/contract"
}
catch{
	echo "Following Error Occured while fetching orgId: $_ "
	Exit
}
$response=$response.Content | ConvertFrom-Json
$orgId=$response.orgId
$fileName="param.json"
New-Item -Path $fileName -ItemType File -Force
Add-Content $fileName "[{`"ParameterKey`":`"Section1aSumoLogicDeployment`",`"ParameterValue`":`"${deployment}`"},"
Add-Content $fileName "{`"ParameterKey`":`"Section1bSumoLogicAccessID`",`"ParameterValue`":`"${SUMO_ACCESS_ID}`"},"
Add-Content $fileName "{`"ParameterKey`":`"Section1cSumoLogicAccessKey`",`"ParameterValue`":`"${SUMO_ACCESS_KEY}`"},"
Add-Content $fileName "{`"ParameterKey`":`"Section1dSumoLogicOrganizationId`",`"ParameterValue`":`"${orgId}`"},"

$awscmd=aws sts get-caller-identity --profile ${AWS_PROFILE}
$json = @"
$awscmd
"@
$x = $json | ConvertFrom-Json
$awsAccountId = $x.Account
Add-Content $fileName "{`"ParameterKey`":`"Section2aAccountAlias`",`"ParameterValue`":`"${awsAccountId}`"}]"

$stackName="sumoawsoquicksetup"
$now=Get-Date
echo "AWS Observability Script Configuration completed. Triggering CloudFormation Template at : $now"
aws cloudformation create-stack --profile ${AWS_PROFILE} --region ${AWS_REGION} --template-url ${masterTemplateURL} --stack-name $stackName --parameter file://param.json --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
if($LASTEXITCODE -ne 0){
	echo "Error Occured in aws cloudformation command"
	Remove-Item param.json
	Exit
}
Remove-Item param.json

$now=Get-Date
echo "AWS Observability Script completed at : $now"
echo "Please return to Sumo Logic UI to continue."