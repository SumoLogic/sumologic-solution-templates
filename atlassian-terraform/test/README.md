# Unit Tests for Sumo Logic Atlassian Terraform

The tests verify/run following:
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

#### Integration Tests for Sumo Logic Atlassian Terraform

[Terratest](https://terratest.gruntwork.io/) is being used for Integration testing of the Sumo Logic Atlassian Terraform scripts.

Following objects are verified:

1. Sumo Logic:

    a. Collector.
    b. Sources for each app i.e. Jira Server, Jira Cloud, Opsgenie, Bitbucket.
    c. App installation for Atlassian, Jira Cloud, Jira Server, Opsgenie and Bitbucket.
    c. Webhooks for Jira Cloud, Jira Server, Jira Service Desk and Opsgenie.

2. Atlassian

    a. Opsgenie Integration.


#### Running integration tests


1. Configure the execution options in `sumologic.auto.tfvars`, `atlassian.auto.tfvars` and `webhooks.auto-tfvars`.
2. Configure your Sumo Logic Username by setting the environment variable:

    a. `SUMOLOGIC_USERNAME`, it should be the same user with which the access id is created.

3. Install Terraform and make sure it's on your PATH.
4. Install Golang and make sure it's on your PATH.
5. Execute Tests

    ```shell
    cd test
    dep ensure
    go test -v -timeout 30m
    ```
6. The tests are divided into multiple stages:

    a. deploy
    b. validateSumoLogic
    c. validateAtlassian
    d. cleanup

    All the stages are executed by default. If you would like to skip a stage set the environment variables like `SKIP_deploy=true`.
    This is very helpful for example if you are modifying the code and do not want to create/destroy resources with each test run.
    To achieve this, for the first run you would set `SKIP_cleanup=true` and all other variables should be unset.
    For the second run it would be `SKIP_cleanup=true` and `SKIP_deploy=true`.

    Now, you can run tests without creating/destroying resources with each run. Once you are finished, unset `SKIP_cleanup` and run the tests to clean up the resources.
