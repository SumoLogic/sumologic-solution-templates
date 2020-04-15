# Unit Tests for Sumo Logic atlassian-terraform

The tests verify/run following:
1. `terraform` installation.
2. `tflint` installation.
3. Run `tflint`.
4. Run `terraform init`. Make sure third party plugins are installed otherwise this will fail.
5. Run `terraform validate`.
6. Run `terraform fmt`.

#### Running tests for Sumo Logic atlassian-terraform

```shell
cd test
sh unit_tests.sh
```

