## Pre-requisites

- AWS cli configured
- Git
- Golang
- Terraform
- Sumo account (Preferably new) to run this test suite or any account which does not have conflicting resources with AWSO

## Source Module
### How to run Test automation 
1. Clone git repository
2. Set variables at following 2 files
2.1 aws-observability-terraform/examples/sourcemodule/testSource/main.auto.tfvars
2.2 aws-observability-terraform/examples/sourcemodule/overrideSources/main.auto.tfvars
3. Provide Existing collectorID and S3 bucket at function TestSourceModule4 at
3.1 aws-observability-terraform/test/sourcemodule/source_test.go
4. Go to folder aws-observability-terraform and run following command to execute all Test functions, with function name pattern as Test* 
```go test -v -timeout 50m ./test/sourcemodule```
5. Go test command runs all functions starting with name Test*. So if you want to run a particular test case according to your use case, comment the rest of the Testing functions. It’ll take less time to run than running all test cases.
6. For example if you only run testcase 3 you can expect successful test execution as follows:

### Success Criteria
If all the test cases are passed successfully, then you can expect the below output. 

### Failure Criteria
If any of the test cases failed, then you can expect the below output. 

### Limitations
While running multiple test cases if any of the test cases failed then you need to do manual cleanup of the resources created. Alternatively you can go to following folders aws-observability-terraform/examples/appmodule and run terraform destroy on each of the following folders manually to cleanup resources created.
 - aws-observability-terraform/examples/sourcemodule/testSource
 - aws-observability-terraform/examples/sourcemodule/overrideSources

### How to Update Test Suite
Codebase for App Module test cases is present at : aws-observability-terraform/test/sourcemodule
1. If any resource is added / removed from the solution
1.1 Modify all the Test case functions at source_test.go . 
1.2 Add / Remove the respective validation. E.g. If Classic LB gets deprecated from AWSO then followings things will have to be performed (wrt test framework only)
   - Remove its sumo source validation.
   - Remove validations for all the AWS resources created as a part of it such as SNS topic, SNS subscription, CF stack, etc.
   - Similarly If any new service is added, write validations
2. If New AWS entity is added to AWSO Solution
Currently we have validations for following entities, If apart from them any new entity is added please add its validation on similar lines at validateAWS.go.
2.1 validateS3Bucket
2.2 validateSNSTopic
2.3 validateSNSsub
2.4 validateIAMRole
2.5 validateCloudTrail
2.6 validateLambda
2.7 validateCFStack
2.8 validateKFstream
2.9 validateCWmetricstream


### Miscellaneous Links
https://docs.google.com/spreadsheets/d/1tPC4lZPfQTXxfNLqr3oVXFCQH0PjZouNQAnbt4LSU8k/edit#gid=1162903618
https://docs.google.com/document/d/1PsNXkmL6Jo_2Q5f4mO0MvK1Dojl6KfY8SyybpE-g1gg/edit?usp=sharing