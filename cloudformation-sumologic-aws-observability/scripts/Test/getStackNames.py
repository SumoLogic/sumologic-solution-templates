import boto3

# Create a CloudFormation client
cf_client = boto3.client('cloudformation')

# # List stacks
# response = cf_client.list_stacks(
#     StackStatusFilter=[
#         'CREATE_COMPLETE', 'UPDATE_COMPLETE'
#     ]
# )
#
# l1 = []
# # Print the stack names
# for stack in response['StackSummaries']:
#     if "AutoEnableOptions" in stack['StackName']:
#         l1.append(stack['StackName'])
#
# l1.sort()
# auto_enable_options = l1[-1]
# print("auto_enable_options", auto_enable_options)
#
# # Describe the stack
# response = cf_client.describe_stacks(
#     StackName=auto_enable_options
# )
#
# # Print stack details
# # Extract and print parameters
# for stack in response['Stacks']:
#     if 'Parameters' in stack:
#         print("Parameters:")
#         for param in stack['Parameters']:
#             print(f"  {param['ParameterKey']}: {param['ParameterValue']}")
#     else:
#         print("No parameters found.")

import boto3


def get_child_stacks(parent_stack_id):
    # Initialize the CloudFormation client
    cf_client = boto3.client('cloudformation')

    # Describe the resources of the parent stack
    resources_response = cf_client.describe_stack_resources(
        StackName=parent_stack_id
    )

    child_stacks = []

    # Loop through the resources to find nested stacks (Type: AWS::CloudFormation::Stack)
    for resource in resources_response['StackResources']:
        if resource['ResourceType'] == 'AWS::CloudFormation::Stack':
            # If the resource is a nested stack, gather its details
            nested_stack_id = resource['PhysicalResourceId']
            try:
                # Describe the nested stack to get its details
                nested_stack_response = cf_client.describe_stacks(
                    StackName=nested_stack_id
                )
                child_stacks.append(nested_stack_response['Stacks'][0])
            except Exception as e:
                print(f"Error fetching nested stack {nested_stack_id}: {e}")

    return child_stacks


# Example usage
parent_stack_id = 'arn:aws:cloudformation:ap-southeast-1:205654718605:stack/noCloudTrailAndInventoryapsoutheast1/6287b4b0-9057-11ef-885c-0aa7be1392f7'
child_stacks = get_child_stacks(parent_stack_id)

# Output the child stack details
if child_stacks:
    for child_stack in child_stacks:
        print(f"Child Stack Name: {child_stack['StackName']}")
        print(f"Child Stack Status: {child_stack['StackStatus']}")
        print(f"Creation Time: {child_stack['CreationTime']}")
else:
    print("No child stacks found.")
