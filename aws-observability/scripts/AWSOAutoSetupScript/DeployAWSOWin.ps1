try{
$awsCheck=aws --version
}
catch{
	echo "aws cli not installed. Please install aws cli and rerun the script"
	Exit
}
$now=Get-Date
echo "Script initiated at : $now"
#input to the script is sumo accessId and accessKey
$SUMO_ACCESS_ID = $args[0]
$SUMO_ACCESS_KEY = $args[1]
if(-not $AWS_PROFILE){
	$AWS_PROFILE="default"
}
#identify sumo deployment associated with sumo accessId and accessKey
$apiUrl="https://api.sumologic.com"
$deployment="us1"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "$SUMO_ACCESS_ID","$SUMO_ACCESS_KEY")))

try{
$result = Invoke-WebRequest -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}  -Uri "https://api.sumologic.com/api/v1/collectors/"
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
Add-Content $fileName "[`"Section1aSumoLogicDeployment=${deployment}`","
Add-Content $fileName "`"Section1bSumoLogicAccessID=${SUMO_ACCESS_ID}`","
Add-Content $fileName "`"Section1cSumoLogicAccessKey=${SUMO_ACCESS_KEY}`","
Add-Content $fileName "`"Section1dSumoLogicOrganizationId=${orgId}`","

$awscmd=aws sts get-caller-identity
$json = @"
$awscmd
"@
$x = $json | ConvertFrom-Json
$awsAccountId = $x.Account
Add-Content $fileName "`"Section2aAccountAlias=${awsAccountId}`"]"
aws s3 cp s3://sumologic-appdev-aws-sam-apps/aws-observability-versions/v2.5.0/sumologic_observability.master.template.yaml sumologic_observability_template.yaml



$stackName="sumoawsoquicksetup"
$now=Get-Date
echo "Script Configuration completed. Triggering CloudFormation Template at : $now"
aws cloudformation deploy --profile ${AWS_PROFILE} --template-file sumologic_observability_template.yaml --stack-name $stackName --parameter-overrides file://param.json --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
if($LASTEXITCODE -ne 0){
	echo "Error Occured in aws cloudformation command"
	Exit
}
Remove-Item param.json

$now=Get-Date
echo "Script completed at : $now"
