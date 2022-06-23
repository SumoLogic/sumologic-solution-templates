# AWSO TF App Module Test Automation

## Pre-requisites

- AWS cli configured
- Git
- Golang
- Terraform
- Sumo account (Preferably new) to run this test suite or any account which does not have conflicting resources with AWSO

## App Module
### How to run Test automation 
1. Clone git repository
2. Set variables at following file
   - aws-observability-terraform/examples/appmodule/main.auto.tfvars
3. Now Go back to folder aws-observability-terraform and run following command to execute all Test functions, with function name pattern as Test*
```go test -v -timeout 50m ./test/appmodule```
4. Go test command runs all functions starting with name Test*. So if you want to run a particular test case according to your use case, comment the rest of the Testing functions. It’ll take less time to run than running all test cases.
5. In case of failure - you can determine the cause of failure, fix the issue and re-run the failed test case.
6. For example if you only run testcase 3 you can expect successful test execution as follows:

### Success Criteria
If all the test cases are passed successfully, then you can expect the below output. 

### Failure Criteria
If any of the test cases failed, then you can expect the below output. 
### Limitations
While running multiple test cases if any of the test cases failed then you need to do manual cleanup of the resources created. Alternatively you can go to folder aws-observability-terraform/examples/appmodule and run terraform destroy here manually to cleanup resources created.
### How to Update Test Suite
Codebase for App Module test cases is present at : ```aws-observability-terraform/test/appmodule```
1. If any resource is added / removed from the solution
   - Modify the function validateSumoLogicResources at ```validateSumo.go```
   - Add / Remove the respective validation
2. If New Sumo entity is added to AWSO Solution
Currently we have validations for following entities, If apart from them any new entity is added please add its validation on similar lines at ```validateSumo.go.```
   - validateSumoLogicAppsFolder
   - validateSumoLogicFER
   - validateSumoLogicField
   - validateSumoLogicMetricRule
   - validateSumoLogicMonitorsFolder
   - validateSumoLogicHierarchy


### Miscellaneous Links
https://docs.google.com/spreadsheets/d/1tPC4lZPfQTXxfNLqr3oVXFCQH0PjZouNQAnbt4LSU8k/edit#gid=1162903618
https://docs.google.com/document/d/1PsNXkmL6Jo_2Q5f4mO0MvK1Dojl6KfY8SyybpE-g1gg/edit?usp=sharing
