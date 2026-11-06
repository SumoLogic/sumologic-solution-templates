# AWS Observability Solution


The AWS Observability Solution provides an established framework to simplify the monitoring and troubleshooting of your AWS cloud infrastructure. The AWS Observability Solution can be deployed across multiple accounts and regions:
- minimizing the time it takes to get operational insights across your AWS infrastructure.
- identifying elements that are subject to specific operational issues across your AWS infrastructure.
- minimizing the time it takes to assign operational to the correct business units and functional teams in your AWS infrastructure.

For more details, Please look at [Sumo Logic AWS Observability Help Document](https://help.sumologic.com/Observability_Solution/AWS_Observability_Solution).

## Using AWS Observability with Sumo Logic API Allowlist

When Sumo Logic API allowlist is enabled, Lambda functions calling Sumo Logic APIs must use a static outbound IP. Deploy [static_outbound_ip.template.yaml](templates/static_outbound_ip.template.yaml) to create a NAT Gateway with Elastic IP network, AWS Observability picks it up automatically from SSM Parameter Store (`/sumologic/awso/network`).

1. Deploy `static_outbound_ip.template.yaml` in each account and region where AWS Observability is deployed.
   - `NewVPC` - creates VPC, Internet Gateway, public subnet, NAT Gateway with Elastic IP and two private subnets.
   - `ExistingVPC` - validates the existing VPC and creates only the missing components (Internet Gateway, NAT Gateway, NAT routed private subnets, security group). Customer owned resources are never modified or deleted.
   - Optionally provide an existing Elastic IP allocation ID already added to the allowlist.
   - Single account: pass the inputs as parameters (`Existing VPC ID`, `Existing Private Subnet IDs`, `Existing Elastic IP Allocation ID`, `Existing Security Group ID`). Only the VPC ID is required.
   - StackSets: leave those parameters blank and publish the same inputs in SSM Parameter Store in each account and region instead, so one set of StackSet parameters works everywhere. Only `vpc-id` is required, the others are optional. A parameter wins over the SSM value for the same input:

     ```
     aws ssm put-parameter --name /sumologic/awso/network/vpc-id --type String --value vpc-0abc1234
     # optional: private-subnet-ids, elastic-ip-allocation-id, security-group-id under /sumologic/awso/network/
     ```

     For many accounts and regions, list them in a CSV (see `scripts/static_ip_ssm_inputs.sample.csv`) and run `python3 scripts/StaticIpSsmInputsPopulate.py -f inputs.csv --dry-run`, then again without `--dry-run`.
2. Add the `NatPublicIp` stack output to Sumo Logic API allowlist.
3. Deploy or update AWS Observability. AWS Observability checks SSM Parameter Store on every deployment, update and upgrade. If AWS Observability is already deployed, update the stack (any parameter change) or upgrade it to pick up the network. CloudFormation rejects an update with no changes. The static outbound IP used is shown in stack output `SumoAPIOutboundIP`.

Notes:
- Delete the AWS Observability stack before deleting the static outbound IP stack, Sumo Logic resources are removed through the NAT Gateway.
- For StackSets, deploy `static_outbound_ip.template.yaml` as a StackSet to the same accounts and regions, wait for it to finish, then deploy AWS Observability. Each account and region gets its own NAT IP, add all of them to the allowlist. Delete the AWS Observability StackSet before the network StackSet.
- NAT Gateway and Elastic IP incur additional AWS cost. See [docs/design/AWSO-StaticOutboundIP-Design.md](docs/design/AWSO-StaticOutboundIP-Design.md) for design details.

## License

The AWS Observability is licensed under the apache v2.0 license.

## Issues

Raise issues at [Issues](https://github.com/SumoLogic/sumologic-solution-templates/issues)

## Change Log

For Full Change Log, please visit [Releases](https://github.com/SumoLogic/sumologic-solution-templates/releases) page.

## Contributing

* Fork the project on [Github](https://github.com/SumoLogic/sumologic-solution-templates).
* Make your feature addition or fix bug, write tests and commit.
* Create a pull request with one of maintainer's as Reviewers.
