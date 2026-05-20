import boto3

# Initialize a session using Amazon CloudWatch
client = boto3.client('logs')

prefix = '/aws/lambda/awso2.11'


def delete_log_groups_with_prefix(prefix):
    paginator = client.get_paginator('describe_log_groups')
    for page in paginator.paginate(logGroupNamePrefix=prefix):
        for log_group in page['logGroups']:
            log_group_name = log_group['logGroupName']
            try:
                response = client.delete_log_group(
                    logGroupName=log_group_name
                )
                print(f"Deleted log group: {log_group_name}")
            except Exception as e:
                print(f"Error deleting log group {log_group_name}: {e}")


if __name__ == "__main__":
    delete_log_groups_with_prefix(prefix)
