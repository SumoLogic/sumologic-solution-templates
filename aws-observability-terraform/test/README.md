# sumologic-aws-observability testing


This testing suite runs a series of integration tests for the aws-observability terraform module

## Requirements 

| Name | Version |
|------|---------|
| terraform | ~> 0.13 |
| Go | ~> 1.14 |



## Setup

This testing suite requires additional terratest utilities in addition to the base go package, to install the terratest utilities: 

```bash
# Curl the binary
curl --location --silent --fail --show-error -o terratest_log_parser https://github.com/gruntwork-io/terratest/releases/download/v0.13.13/terratest_log_parser_linux_amd64
# Make the downloaded binary executable
chmod +x terratest_log_parser
#  Move terratest_log_parser
sudo mv terratest_log_parser /usr/local/bin

```

After install, write the following environment variables into `<module-name>/run_tests.sh`:

| Variable | 
|------ |
| AWS_REGION | 
| SUMOLOGIC_ACCESSKEY | 
| SUMOLOGIC_ACCESSID | 
| SUMOLOGIC_ENVIRONMENT | 
| ACCOUNT_ALIAS | 
| SUMOLOGIC_ORGANIZATIONID | 


## Usage


```bash 
cd ./<module_name>/run_tests.sh <optional test name> <optional timeout in minutes>
```

If running individual test, the optional timeout is required: 


```bash 
cd ./common_test/run_tests.sh TestCommonAll 15
```


Testing outputs will be sent to `<module_name>/common_test/` with the following files: 

| File/Dir | Description |
|------|---------|
| report.xml | XML Style summary of tests for integration into UI CI/CD|
| summary.log | Summary log of which test cases passed/failed|
| <module_name>/ | Directory that has results of each sub-test , helpful for debugging individual test failures |
| <module_name>.log | Full log of test output |

