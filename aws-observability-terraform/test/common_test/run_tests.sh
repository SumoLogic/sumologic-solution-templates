export ACCOUNT_ALIAS=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ENVIRONMENT=
export SUMOLOGIC_ACCESSID=
export SUMOLOGIC_ORGANIZATIONID=
export AWS_REGION=

if [ $# -eq 0 ]
then
    go test -v -timeout 30m -run | tee test_output.log
    terratest_log_parser -testlog test_output.log -outputdir test_output
else 
    go test -v -timeout $2 -run ^$1 | tee test_output.log
    terratest_log_parser -testlog test_output.log -outputdir test_output
fi


