# Unit/Integration Tests for Sumo Logic AWS Observability Terraform.

#### Unit Tests

The unit tests verify/run following:
1. `terraform` installation.
2. `tflint` installation.
3. Run `tflint`.
4. Run `terraform init`. Make sure third party plugins are installed otherwise this will fail.
5. Run `terraform validate`.
6. Run `terraform fmt`.

#### Running unit tests

```shell
cd test
sh unit_tests.sh
```

#### Integration Tests

[Terratest](https://terratest.gruntwork.io/) is being used for Integration testing of the Sumo Logic AWS Observability Terraform scripts.

Following objects are verified:

1. AWS:

    * CloudFormation Installation Successful.
 
2. Sumo Logic
    * Validate if provided Sumo Logic Access Key and Access ID are valid. 

#### Running integration tests


1. Configure the execution options in `main_variables.auto.tfvars`.
2. Configure AWS Provider in `main.tf`

3. Install Terraform and make sure it's on your PATH.
4. Install Golang and make sure it's on your PATH.
5. Execute Tests

    ```shell
    cd test
    dep ensure
    AWS_PROFILE="YOUR PROFILE" go test -v -timeout 90m
    ```
