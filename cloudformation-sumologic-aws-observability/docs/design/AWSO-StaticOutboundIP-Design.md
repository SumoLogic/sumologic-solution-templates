# AWSO: Static Outbound IP for the Sumo Logic API Allowlist (Design)

| | |
|---|---|
| Status | Implemented, pending AWS integration tests (11.3 to 11.6) |
| Applies to | AWS Observability (AWSO) CloudFormation v3.1.0 |
| Components | `static_outbound_ip.template.yaml` (new), `resources.template.yaml`, `sumologic_observability.master.template.yaml`, `sumologic_observability.mp.yaml`, `sumologic-app-utils` Lambda, `scripts/StaticIpSsmInputsPopulate.py` (new) |

## 1. Problem
When a customer turns on the Sumo Logic **API allowlist**, AWSO install and upgrade fail.

During deployment, the `LambdaHelper` Lambda calls Sumo Logic APIs to create Fields, FERs, Collectors, Sources and Apps. Lambdas run on AWS-managed networking, so their outbound IPs are dynamic AWS public addresses that can't be predicted. The allowlist rejects those calls, and the stack fails.

## 2. Goals and non-goals
**Goals**
- AWSO install, upgrade and delete succeed with the allowlist on.
- No new required inputs in AWSO. The feature is detected automatically.
- Supports a **new VPC**, or an **existing VPC** where only the missing components are created.
- No change at all for customers who don't use the feature.

**Non-goals**
- Updating the Sumo allowlist automatically. That isn't possible, because the API is the thing that's blocked.
- Moving non-Sumo-API Lambdas into a VPC: Telemetry, auto-enable, log group connector, DLQ, Kinesis Firehose and Secrets retrieval.
- Multi-AZ NAT high availability. Version 1 uses a single NAT gateway.

## 3. Alternatives considered
| Option | Outcome |
|---|---|
| Temporarily disable the allowlist during install | Simple, but weakens security and needs manual coordination. Kept only as a documented fallback |
| Install via Terraform from an allowlisted static host | Works only for Terraform users with static hosts |
| NAT/EIP created **inside** AWSO | Chicken-and-egg: the EIP doesn't exist yet when AWSO first calls the Sumo API, so it can't be on the allowlist |
| **Separate network stack + SSM handoff (chosen)** | The network and its IP exist before AWSO runs. The customer allowlists the IP once, and AWSO picks the network up automatically |

## 4. Solution overview
```
┌──────────────────────────────┐   writes    ┌──────────────────────────────┐
│ static_outbound_ip stack     │ ──────────▶ │ SSM Parameter Store          │
│ (VPC, IGW, NAT+EIP, subnets, │             │ /sumologic/awso/network/*    │
│  SG) – once per acct/region  │             └──────────────┬───────────────┘
└──────────────────────────────┘                            │ reads (if present)
                                                            ▼
                                  ┌───────────────────────────────────────────┐
                                  │ AWSO stack                                │
                                  │ NetworkConfigRetrieval ─▶ CreateCommon    │
                                  │ Resources: LambdaHelper(+Alias) VpcConfig │
                                  └───────────────────┬───────────────────────┘
                                                      ▼
                    Lambda ─▶ Private subnet ─▶ NAT GW (EIP) ─▶ IGW ─▶ Sumo Logic API
```
**Customer flow**
1. Deploy `static_outbound_ip.template.yaml`.
2. Add the `NatPublicIp` output to the Sumo Logic API allowlist.
3. Deploy or upgrade AWSO. It detects the SSM values and attaches its Lambdas to the VPC.

### 4.1 Deployment flows

**A. Single account and region**

```
 Customer
    │
    │ 1. (ExistingVPC only) pass the inputs as stack parameters:
    │      VPC ID (required), private subnets, Elastic IP, security group (optional)
    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ static_outbound_ip stack                                                     │
│                                                                              │
│   NetworkOption = NewVPC                 NetworkOption = ExistingVPC         │
│   ─────────────────────                  ───────────────────────────         │
│   CloudFormation creates:                StaticIpNetworkSetupFunction runs   │
│   VPC, IGW, public subnet,               VPCNetworkSetup:                    │
│   NAT GW + EIP, 2 private subnets,        - read parameters (win), then SSM  │
│   security group                          - validate what was supplied       │
│                                           - discover NAT-routed subnets      │
│                                           - create only what is missing      │
│                                             (IGW, public subnet, EIP, NAT,   │
│                                              2 private subnets, SG)          │
│                                                                              │
│   Writes SSM /sumologic/awso/network/{private-subnet-ids, security-group-id, │
│                                       vpc-id}, then nat-public-ip (last)     │
│   Output: NatPublicIp                                                        │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │ 2. NatPublicIp
                                       ▼
                         Customer adds the IP to the Sumo Logic API allowlist
                                       │
                                       │ 3. deploy / update / upgrade AWSO
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ AWSO stack                                                                   │
│   NetworkConfigRetrieval reads /sumologic/awso/network/*                     │
│     nat-public-ip missing  ─▶ "Not configured": Lambdas run without VPC      │
│     all present            ─▶ validate subnets + SG against vpc-id           │
│                               ─▶ LambdaHelper(+Alias) get VpcConfig          │
│     nat-public-ip present, others missing ─▶ fail: incomplete configuration  │
│   Output: SumoAPIOutboundIP                                                  │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       ▼
        Lambda ─▶ private subnet ─▶ NAT GW (EIP) ─▶ IGW ─▶ Sumo Logic API (allowlisted IP)
```

**B. Multiple accounts and regions (StackSets)**

A StackSet cannot take a different parameter value per account and region without overrides, and VPC IDs differ in every instance. So the inputs are published in SSM once per account and region, and the StackSet uses the same parameters everywhere.

```
 Customer (once per account and region, before the StackSet)
    │  python3 scripts/StaticIpSsmInputsPopulate.py -f inputs.csv   (one CSV row per account/region)
    │  writes vpc-id (+ optional private-subnet-ids, elastic-ip-allocation-id, security-group-id)
    ▼
┌─────────────────────────┐  ┌─────────────────────────┐       ┌───────────────────┐
│ Account A / us-east-1   │  │ Account A / eu-west-1   │  ...  │ Account N / region│
│ SSM: vpc-id = vpc-aaa   │  │ SSM: vpc-id = vpc-bbb   │       │ SSM: vpc-id = ... │
└────────────┬────────────┘  └────────────┬────────────┘       └─────────┬─────────┘
             │                            │                              │
             └────────────────────────────┴──────────────┬───────────────┘
                                                         │
 Step 1: network StackSet (ExistingVPC, identical parameters, VPC parameters left blank)
                                                         ▼
          Each instance runs the single-account flow A on its own account and region:
          read SSM inputs ─▶ validate ─▶ create what is missing ─▶ write SSM outputs
          Each instance has its own NatPublicIp
                                                         │
 Step 2: collect every instance's NatPublicIp output     │
         and add all of them to the Sumo Logic API allowlist
                                                         │
 Step 3: wait until the network StackSet operation has finished on all instances
                                                         ▼
 Step 4: AWSO StackSet (same accounts and regions)
          each instance's NetworkConfigRetrieval reads its own account and region SSM
          ─▶ Lambdas attach to that instance's VPC ─▶ calls leave through that instance's NAT IP
                                                         │
 Delete order (reverse):                                 ▼
   1. AWSO StackSet (its Sumo cleanup still needs the NAT path)
   2. network StackSet (removes only tagged resources; customer inputs in SSM stay)
```

| | A. Single account and region | B. Multiple accounts and regions |
|---|---|---|
| How inputs are given | Stack parameters, or SSM | SSM per account and region; StackSet parameters stay identical |
| Network option | `NewVPC` or `ExistingVPC` | `ExistingVPC` with blank VPC parameters, or `NewVPC` |
| NAT IPs to allowlist | 1 | One per account and region |
| Ordering | Network stack, allowlist, AWSO | Inputs in SSM, network StackSet finished, allowlist, AWSO StackSet |
| Missing SSM `vpc-id` | Fails with the path, account and region | That instance fails with the path, account and region. Whether the remaining instances continue depends on the StackSet failure tolerance setting |

## 5. Scope: which Lambdas change
| Lambda | Template | Calls Sumo API | Change |
|---|---|---|---|
| `LambdaHelper` | resources.template.yaml:535 | Yes. ServiceToken for every Custom::Sumo* resource, including those in `cloudwatchmetrics` (`LambdaARN`) and `apps` (`Section3aParentStackLambdaARN`) | Add VpcConfig |
| `LambdaHelperAlias` | resources.template.yaml:588 | Yes (`Custom::AccountAlias`) | Add VpcConfig |
| TelemetryLambda, auto-enable, loggroup, DLQ, KF, SecretsRetrieval | various | No | None |

## 6. Component design

### 6.1 `static_outbound_ip.template.yaml` (new, standalone)

**Parameters** (the SSM path is fixed in a `StaticOutboundIP` mapping, there is no prefix parameter)
| Param | Default | Notes |
|---|---|---|
| `Section1aNetworkOption` | `NewVPC` | `NewVPC` \| `ExistingVPC` |
| `Section1bElasticIPAllocationId` | `""` | Optional. Reuses an EIP that's already on the allowlist; if blank, SSM `elastic-ip-allocation-id` is used for `ExistingVPC` when present, otherwise one is created |
| `Section2aVpcCidr` | `10.250.0.0/24` | `NewVPC` only. `!Cidr [cidr, 3, 6]` gives three /26 blocks: public, private-a and private-b |
| `Section3aExistingVpcId` | `""` | `ExistingVPC` only. If blank, the VPC ID is read from SSM `/sumologic/awso/network/vpc-id` in the same account and region |
| `Section3bExistingPrivateSubnetIds` | `""` | Optional. Each subnet must route `0.0.0.0/0` to a NAT. If blank, SSM `private-subnet-ids` is used when present |
| `Section3cExistingSecurityGroupId` | `""` | Optional, `ExistingVPC` only. Must be in the VPC and allow outbound `tcp/443`; never modified. If blank, SSM `security-group-id` is used when present, otherwise a tagged group is created |

**Conditions:** `new_vpc`, `existing_vpc`, `eip_provided`, `create_eip` (NewVPC and no EIP), `lookup_eip` (NewVPC and EIP given), `use_helper` (ExistingVPC or lookup_eip).

**NewVPC resources** (plain CloudFormation):
- VPC with DNS support and hostnames turned on.
- IGW and its attachment.
- `PublicSubnet` in AZ 0, with a route table: `0.0.0.0/0` → IGW.
- `NatEIP` (only when `create_eip`).
- `NatGateway` in the public subnet. `DependsOn` is the public route.
- `PrivateSubnetA` and `PrivateSubnetB` in AZs 0 and 1, sharing a route table: `0.0.0.0/0` → NAT.
- Every resource is tagged `Name=sumologic-awso-*` and `CreatedBy=sumologic-awso`.

**Helper resources** (`use_helper`):
- **`StaticIpNetworkSetupFunction`:** sumo-app-utils, `main.handler`, python3.14, timeout 900. It runs outside the VPC and only calls EC2 APIs.
- **`StaticIpNetworkSetupRole`:**
  - `ec2:Describe*`
  - Security group create and delete (delete only when tagged), `ec2:DescribeVpcAttribute`
  - `ssm:GetParameters`, `PutParameter`, `AddTagsToResource`, `ListTagsForResource` on the prefix path; `ssm:DeleteParameter` only when tagged
  - Create actions for subnets, route tables, routes, IGW, NAT and addresses
  - `ec2:CreateTags`, only alongside those create actions
  - Delete, detach and release actions, **only when the resource has the tag `CreatedBy=sumologic-awso`**
- **`ElasticIPLookup`** (`Custom::ElasticIPLookup`): takes an `AllocationId` and returns its `PublicIp`.
- **`VPCNetworkSetup`** (`Custom::VPCNetworkSetup`): takes `VpcId`, `ElasticIPAllocationId`, `PrivateSubnetIds`, `SecurityGroupId`, `StackId` and `SSMPrefix`. Returns `VpcId`, `SubnetIds`, `SecurityGroupId` and `NatPublicIp`.

**`NewVPC` only (for `ExistingVPC` the helper creates or validates the group and writes the SSM outputs)**
- **`LambdaSecurityGroup`:** no ingress rules; egress allows `tcp/443` to `0.0.0.0/0`.
- **SSM parameters**, written under the fixed path `/sumologic/awso/network` (see 6.4 for how this namespace is shared with customer-published inputs). `NewVPC` writes them as `AWS::SSM::Parameter` resources, `nat-public-ip` last. `ExistingVPC` outputs are written by the helper, because the customer may already have published some of the same names and CloudFormation cannot adopt an existing parameter:

| Name | Type | Value |
|---|---|---|
| `private-subnet-ids` | StringList | New private subnets, or `VPCNetworkSetup.SubnetIds` |
| `security-group-id` | String | `LambdaSecurityGroup` |
| `nat-public-ip` | String | `NatEIP`, `ElasticIPLookup.PublicIp`, or `VPCNetworkSetup.NatPublicIp` |
| `vpc-id` | String | The VPC that was created or provided |

**Outputs:** `VpcId`, `PrivateSubnetIds`, `SecurityGroupId` and `NatPublicIp` ("Add this IP to the Sumo Logic API allowlist"). For `ExistingVPC` they come from `VPCNetworkSetup`.

**`LambdaSecurityGroup`** is created in the template for `NewVPC` only. For `ExistingVPC` the helper validates a supplied group or creates a tagged one, because a CloudFormation condition cannot depend on what SSM holds.

### 6.2 `Custom::VPCNetworkSetup`: check what exists, create only what's missing
This is a new class in `sumologic-app-utils/src/awsresource.py`. It follows the existing `AWSResource` subclass pattern (see `EnableS3LogsResources`, line 204) and is auto-registered by `AutoRegisterResource`.

**Create**

| Step | Check | If missing |
|---|---|---|
| 1. IGW | IGW attached to the VPC | Create, attach and tag |
| 2. NAT | `available` NAT gateway in the VPC (read its `PublicIp`) | Use the given EIP, or allocate and tag one. Find a public subnet (route to `igw-`); create the subnet and route table if there isn't one. Create the NAT and wait until it's available |
| 3. Private subnets | Given subnets must have a route table (explicit or main) that sends `0.0.0.0/0` to `nat-` | Given subnet without that route: **fail**, naming the subnet; customer route tables are never modified. No subnets given: reuse NAT-routed subnets, or create two /28 subnets in different AZs plus a NAT route table |
| 4. CIDR | A free /28 inside the VPC CIDR blocks (checked with `ipaddress`) | **Fail** with "add a secondary CIDR or pass subnet IDs" |
| 5. VPC | The VPC exists and has DNS support turned on | **Fail**. Lambda cannot resolve the Sumo API host names without DNS |
| 6. Security group | A supplied group is in the VPC and allows outbound `tcp/443` to `0.0.0.0/0`. It is never edited | Create a tagged group with only that egress rule |
| 7. Elastic IP | A supplied EIP exists and, when a NAT is found or supplied, is that NAT's address | **Fail** with a mismatch message instead of silently using the NAT's IP |

Every resource it creates is tagged `CreatedBy=sumologic-awso`, `SumoStackId=<StackId>` and `SumoVpcId=<vpc-id>`.

The physical ID is `vpcnet-<vpc-id>`, and it returns `{VpcId, SubnetIds, SecurityGroupId, NatPublicIp}`.

**Update**
- If the VPC changed, return a new physical ID, so CloudFormation deletes the old resources.
- Otherwise, re-run create. It's idempotent because each step checks before creating.

**Delete**
- The VPC ID comes from the **physical ID** (`<LogicalResourceId>/vpcnet-<vpc-id>`), never from the properties or SSM, which may have changed or been removed by then.
- Deletes only resources tagged with this `SumoStackId`, in this order:
  1. NAT gateway, then wait until it's deleted.
  2. EIP, but only if the helper allocated it.
  3. Route tables.
  4. Subnets, retrying with backoff while Lambda ENIs are released.
  5. IGW: detach, then delete.
  6. The tagged security group, retrying while Lambda ENIs are released.
  7. The SSM parameters this resource wrote (tagged). Customer-published inputs are kept.
- **Customer-owned resources are never touched.** Before deleting anything, delete re-checks the `CreatedBy`, `SumoStackId` and `SumoVpcId` tags itself, on top of the server-side `tag:` filters. Unit tests with moto showed that `describe_nat_gateways` there ignores tag filters, so the server-side filter alone isn't a safe guard.

### 6.3 AWSO changes (automatic detection, no new required input)

**Master and MP templates**
- **`StaticIpConfigLookupFunction` with the `NetworkConfigRetrieval` custom resource.** It always runs. It's inline Python, following the same pattern as `SecretsRetrievalFunction` (mp:789).
  - **Prefix:** comes from the fixed mapping `CommonData.StaticOutboundIP.SSMPrefix` (`/sumologic/awso/network`).
  - **Lookup:** calls `ssm:GetParameters` for all four names. Missing names come back in `InvalidParameters`; it doesn't raise an error.
  - **Configured only when `nat-public-ip` exists.** It is written last by the network stack, and the other names may be inputs the customer published for it (6.4).
  - **All values present:** checks the subnets and security group exist and belong to `vpc-id`, then returns the values.
  - **`nat-public-ip` absent:** returns empty `SubnetIds` and `SecurityGroupId`, and `NatPublicIp="Not configured"`, ignoring any other names. AWSO behaves exactly as it does today.
  - **`nat-public-ip` present but another name missing:** **fails** with "Incomplete static outbound IP configuration under <prefix>".
  - **Re-run triggers:** CloudFormation only re-invokes a custom resource when its properties change, so the resource carries two changing properties. `TemplateVersion` (the MPS3KeyPrefix mapping) makes every upgrade look the values up again. `ParametersHash` is a Base64 hash of the AWSO parameters (the same set as `PrimerInvoke`'s `ToUpdate`, without credentials), so any parameter update looks them up again too. There is no extra user-facing parameter. CloudFormation rejects an update with no changes, so a customer who adds the network stack later updates AWSO with any parameter change, or upgrades.
  - **Role:**
    - `ssm:GetParameters` on `arn:${AWS::Partition}:ssm:${AWS::Region}:${AWS::AccountId}:parameter/sumologic/awso/network/*`
    - `ec2:DescribeSubnets` and `ec2:DescribeSecurityGroups`
    - logs
- **`CreateCommonResources` parameters:**
  - `LambdaSubnetIds: !GetAtt NetworkConfigRetrieval.SubnetIds`
  - `LambdaSecurityGroupIds: !GetAtt NetworkConfigRetrieval.SecurityGroupId`
- **Output:** `SumoAPIOutboundIP`.
- **Not used:** `{{resolve:ssm}}` and `AWS::SSM::Parameter::Value<>`. CloudFormation resolves them even when the parameter is missing, which breaks the default path.

**`resources.template.yaml`**
- **New parameters:** `LambdaSubnetIds` and `LambdaSecurityGroupIds` (CommaDelimitedList, default `""`).
- **New condition:** `attach_lambda_vpc: !Not [!Equals [!Join ["", !Ref LambdaSubnetIds], ""]]`.
- **On `LambdaHelper` and `LambdaHelperAlias`:**
  ```yaml
  VpcConfig: !If [attach_lambda_vpc, {SubnetIds: !Ref LambdaSubnetIds, SecurityGroupIds: !Ref LambdaSecurityGroupIds}, !Ref AWS::NoValue]
  ```
- **On `LambdaRole` and `LambdaRoleAlias`:**
  ```yaml
  ManagedPolicyArns: !If [attach_lambda_vpc, [!Sub "arn:${AWS::Partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"], !Ref AWS::NoValue]
  ```

**`sumologic-app-utils/src/sumologic.py`**
- When a call fails with 401/403 because of an IP or allowlist block, raise an error that points to this setup and to the `SumoAPIOutboundIP` output.

### 6.4 ExistingVPC inputs from SSM (StackSets)
`ExistingVPC` with direct parameters needs one value per account and region, which does not work for a StackSet. Instead the customer publishes the inputs once per account and region at fixed paths, and the StackSet uses the same parameters everywhere.

| SSM name under `/sumologic/awso/network/` | Required | Validation when present | When absent |
|---|---|---|---|
| `vpc-id` | Yes, unless the VPC ID parameter is set | Exists, DNS support on | Fail, naming the path, account and region |
| `private-subnet-ids` | No | Each in the VPC and routing `0.0.0.0/0` to a NAT | Discover NAT-routed subnets, else create two |
| `elastic-ip-allocation-id` | No | Exists, and is the NAT's address when a NAT is found | Allocate one when a NAT must be created (released on delete) |
| `security-group-id` | No | In the VPC, outbound `tcp/443` allowed | Create a tagged group |

**Two ways to give the same four inputs.** Single-account users can pass them as stack parameters (`Section3aExistingVpcId`, `Section3bExistingPrivateSubnetIds`, `Section1bElasticIPAllocationId`, `Section3cExistingSecurityGroupId`). StackSet users publish them in SSM instead, because the IDs differ in every account and region and a StackSet cannot take a different parameter value per instance without overrides. Direct stack parameters win over SSM, per input. SSM cannot hold an empty value, so "not set" means "parameter absent".

The inputs and the outputs share one namespace (`vpc-id`, `private-subnet-ids` and `security-group-id` are both), so:
- **Inputs and outputs are told apart by tag.** Everything the stack writes carries `CreatedBy=sumologic-awso`, `SumoStackId` and `SumoVpcId`. When reading inputs, tagged parameters are ignored, so a rerun never treats its own output as a customer input.
- **`nat-public-ip` is only ever an output**, written last. AWS Observability treats the network as configured only when it exists (6.3). A customer who has published only `vpc-id` before running the network stack does not break an AWSO install.
- **Outputs are never written over customer inputs.** The helper writes only the names the customer did not publish (always `nat-public-ip`).

Single parameter by hand: `aws ssm put-parameter --name /sumologic/awso/network/vpc-id --type String --value vpc-0abc1234`

**Many accounts and regions:** use the populate script, see 6.5.

**Limitation:** CloudFormation re-invokes a custom resource only when its properties change. If an SSM input changes while the stack parameters stay the same, the stack does not notice. Update the stack with a changed parameter.

### 6.5 Populate script: `scripts/StaticIpSsmInputsPopulate.py`
Publishes the `ExistingVPC` inputs (6.4) in SSM for many accounts and regions from one CSV, so the customer does not run `aws ssm put-parameter` in each one. Sample: `scripts/static_ip_ssm_inputs.sample.csv`. Tests: `scripts/test/test_StaticIpSsmInputsPopulate.py`.

**CSV** (one row per account and region; header required; `#` and blank lines ignored; duplicate account/region rows rejected)

| Column | Required | Meaning |
|---|---|---|
| `account_id` | Yes | 12-digit target account |
| `region` | Yes | For example `us-east-1` |
| `vpc_id` | Yes | `vpc-…` |
| `private_subnet_ids` | No | `subnet-a;subnet-b`, separated by `;` because the file is comma separated |
| `elastic_ip_allocation_id` | No | `eipalloc-…` |
| `security_group_id` | No | `sg-…` |
| `role_arn` | No | Role to assume for this row instead of the default |

A blank optional cell means "do not set this parameter". The whole file is validated before anything is written; any error exits with a row-numbered list and nothing is changed.

**Authentication**
- The base identity comes from `-p/--profile`, or boto3's default chain (environment variables, `AWS_PROFILE`, SSO, instance role).
- By default every row assumes `arn:<partition>:iam::<account_id>:role/<role-name>` with `sts:AssumeRole`, **including a row for the profile's own account**. The partition (`aws`, `aws-cn`, `aws-us-gov`) is taken from the caller's ARN.
- With `--current-account-only` nothing is assumed; the profile's own credentials write directly, and a row for any other account fails.
- Permissions needed in each target account: `ssm:GetParameter`, `PutParameter`, `AddTagsToResource`, `ListTagsForResource` on `parameter/sumologic/awso/network/*`; `ssm:DeleteParameter` for `--prune`; `ec2:Describe*` (VPCs, subnets, addresses, security groups, VPC attributes) for `--validate-resources`.

**Behaviour per parameter**

| Parameter state | Result |
|---|---|
| Does not exist | `created`, tagged `ManagedBy=sumologic-awso-static-ip-populate` |
| Exists, same value | `unchanged` |
| Exists, different value | `conflict`, row reported as failed; `updated` with `--overwrite` |
| Tagged `CreatedBy=sumologic-awso` (written by the network stack) | `conflict`, never modified, even with `--overwrite` |
| `nat-public-ip` | Never written by the script |

`private-subnet-ids` is stored as `StringList`, the others as `String`. A failed row never stops the other rows. Rows run in parallel. A JSON report `static_ip_ssm_inputs_report_<timestamp>.json` is written next to the CSV. Exit code: 0 if every row is ok, 1 if any row has an error or conflict, 2 for CSV or usage errors.

**Options**

| Option | Default | Effect |
|---|---|---|
| `-f, --file FILE` | required | CSV file |
| `-p, --profile NAME` | default chain | AWS CLI profile used as the base identity |
| `-r, --role-name NAME` | `OrganizationAccountAccessRole` | Role name assumed in each account; a row's `role_arn` overrides it |
| `--external-id ID` | none | External ID passed to `sts:AssumeRole` |
| `--current-account-only` | off | No role assumption; every row must be the profile's account |
| `-n, --dry-run` | off | Reads and compares, prints what would change, writes nothing. Still needs the assume-role and read permissions |
| `--overwrite` | off | Replace a script-managed or customer parameter that has a different value |
| `--prune` | off | Delete parameters this script created (tag `ManagedBy=sumologic-awso-static-ip-populate`) whose CSV cell is now blank |
| `--validate-resources` | off | Check in each account and region that the VPC exists and has DNS support, and the subnets, EIP and security group exist and belong to the VPC. A row that fails is not written |
| `--max-workers N` | 4 | Number of rows processed in parallel |

**Scenarios**

| # | Scenario | Command | Result |
|---|---|---|---|
| 1 | First look before changing anything | `python3 scripts/StaticIpSsmInputsPopulate.py -f inputs.csv -p mgmt --dry-run` | Prints created/unchanged/conflict per row; nothing is written |
| 2 | Many accounts through an Organizations management profile | `python3 scripts/StaticIpSsmInputsPopulate.py -f inputs.csv -p mgmt` | Assumes `OrganizationAccountAccessRole` in each account and writes in each row's region |
| 3 | Accounts use a different role name | `... -p mgmt -r SumoNetworkAdmin` | Assumes `…:role/SumoNetworkAdmin` in every account |
| 4 | Role needs an external ID | `... -p mgmt -r SumoNetworkAdmin --external-id abc123` | The external ID is sent on every assume-role call |
| 5 | One row needs a different role | Set `role_arn` in that row | That row uses its own role; the others use the default |
| 6 | One account, several regions | `... -p myprofile --current-account-only` | No assume-role; each region in the CSV is written with the profile's credentials |
| 7 | Catch wrong IDs before they reach SSM | `... -p mgmt --validate-resources` | Rows whose VPC, subnet, EIP or security group is missing or in another VPC fail and are not written |
| 8 | A VPC changed and SSM still has the old ID | `... -p mgmt --overwrite` | Different values are replaced; without `--overwrite` they are reported as conflicts |
| 9 | An optional input is no longer wanted | Blank the cell, then `... -p mgmt --prune` | Only script-created parameters are removed; stack-written outputs and customer parameters are kept |
| 10 | Re-run after a partial failure | Same command again | Rows that succeeded show `unchanged`; only failed rows are retried |
| 11 | Large estate | `... -p mgmt --max-workers 8` | More rows in parallel |
| 12 | A parameter already exists from the network stack | Any command | Reported as `conflict` and left alone |

**Order of use:** run the script (scenario 1, then 2 or 6), then deploy the network StackSet, allowlist every `NatPublicIp`, then deploy AWSO (flow B in 4.1).

## 7. Lifecycle and ordering
| Scenario | Behaviour |
|---|---|
| Fresh install, network stack deployed first | Lambdas are created inside the VPC; all Sumo calls go out through the EIP |
| AWSO already installed, network stack added later | Update AWSO with any parameter change, or upgrade it. The Lambdas move into the VPC |
| Network values changed | Requires an AWSO update to take effect |
| Delete | Delete **AWSO first**, because its Sumo cleanup still needs the NAT path. Then delete the network stack (expect slower subnet deletion while ENIs are released) |
| StackSets | Publish `vpc-id` (and any optional inputs, 6.4) in every target account and region. Deploy the network stack as a StackSet with `ExistingVPC` and identical parameters, or with `NewVPC`. Wait for that StackSet operation to finish, then deploy the AWSO StackSet. Each account and region gets its own NAT IP, so every one must be added to the Sumo allowlist. Delete the AWSO StackSet before the network StackSet |

## 8. Security
- The helper's EC2 delete permissions require the `CreatedBy=sumologic-awso` tag, so it can't delete customer resources.
- Customer route tables, NAT gateways and EIPs are never changed or deleted.
- The Lambda security group has no inbound rules and allows only 443 outbound.
- The SSM values aren't secrets, so plain `String` and `StringList` types are used.
- The retrieval role has read-only access, limited to the prefix path. The network helper's `ssm:DeleteParameter` and EC2 deletes are limited to resources tagged `CreatedBy=sumologic-awso`.
- cfn_nag suppressions, each with a written reason: W5, W11, W60, W89 and W92 in the network template; W58 for the lookup function in the master and mp templates.

## 9. Cost
| Item | Approx. |
|---|---|
| NAT gateway | ~$32/month per region, plus ~$0.045/GB processed |
| Elastic IP | Public IPv4 charge (~$3.6/month) |
| Lambda ENIs, SSM Standard parameters | No charge |

Deploy traffic to the Sumo API is small, so the hourly NAT charge is most of the cost. If a NAT gateway already exists in the VPC, `ExistingVPC` reuses it, and nothing new is billed.

## 10. Risks and mitigations
| Risk | Mitigation |
|---|---|
| Customer-published inputs are mistaken for AWSO network config, or the stack's own outputs for inputs | AWSO acts only when `nat-public-ip` exists; inputs are told apart from outputs by tag; AWSO validates subnets and security group against `vpc-id`; the IP in use is shown as the `SumoAPIOutboundIP` output |
| Network stack deleted before AWSO | README ordering; AWSO's Sumo cleanup fails with the clear allowlist error |
| Single NAT is an AZ point of failure | Documented. It only affects the deploy-time Lambdas. Multi-NAT is future work |
| No free CIDR in an existing VPC | Fail with clear guidance (add a secondary CIDR or pass subnet IDs) |
| NAT EIP not on the allowlist | NatPublicIp output and docs; clear 401/403 error |

## 11. Testing
1. **Lint (done):** `cfn-lint` and `cfn_nag` on every template, for each option combination.
2. **Unit tests for `VPCNetworkSetup`** (done, moto; `test_vpc_network_setup.py` and `test_network_config_retrieval.py` in `sumologic-app-utils/Test`):
   - Full VPC: nothing is created.
   - Bare VPC: all components are created.
   - Given subnet without a NAT route: fails.
   - No free CIDR: fails.
   - Delete removes only tagged resources.
3. **Network stack** (manual, on AWS):
   - `NewVPC`, with and without an EIP.
   - `ExistingVPC`, against a full VPC and a bare VPC.
   - Check the SSM values and outputs.
4. **AWSO with the allowlist set to only the NAT IP** (manual, on AWS):
   - Network configured: install succeeds, and the Sumo audit log shows the NAT IP.
   - No SSM values: no VpcConfig is added, and the install fails with the clear error.
   - Some SSM values: fails with the clear error.
5. **Upgrade** (manual, on AWS):
   - v3.0.0 updated with no SSM values: no changes.
   - Add the network, then update AWSO with any parameter change or upgrade it: the Lambdas attach to the VPC.
6. **Delete** (manual, on AWS):
   - AWSO first: Sumo cleanup succeeds.
   - Then the network stack: only its own resources are removed.
7. **Populate script** (done, `scripts/test/test_StaticIpSsmInputsPopulate.py`, moto): CSV validation, create/unchanged/conflict/overwrite, stack-written parameters untouched, dry run, prune, per-row isolation, resource validation.
8. **Test cases** under `templates/test/testcases/static_ip/`.

## 12. Deliverables
- `templates/static_outbound_ip.template.yaml` (new). It is uploaded with the rest of `templates/` by `scripts/YamlToS3.sh`, which has a new `-n/--dry-run` option
- Changes to `templates/resources.template.yaml`, `sumologic_observability.master.template.yaml` and `sumologic_observability.mp.yaml`
- `sumologic-app-utils`: `ElasticIPLookup` and `VPCNetworkSetup` classes, the allowlist error, and the new zip `helper/LambdaFuncs/sumo-app-utils/v3.1.0/sumo-app-utils.zip`
- A README section: "Using AWSO with Sumo Logic API Allowlist"
- `scripts/StaticIpSsmInputsPopulate.py`, `scripts/static_ip_ssm_inputs.sample.csv`, `scripts/test/test_StaticIpSsmInputsPopulate.py` (CSV to SSM inputs for many accounts and regions)
- Unit and integration tests

## 13. Open questions
- Should multi-AZ NAT be an option, or is it future work?
- Should the network stack also support the Terraform AWSO path, using the same SSM contract?
- Do we keep the "temporarily disable the allowlist" option as a documented fallback?
