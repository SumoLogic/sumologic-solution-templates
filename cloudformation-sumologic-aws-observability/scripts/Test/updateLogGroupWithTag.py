import boto3

# Initialize CloudWatch Logs client
client = boto3.client('logs', region_name='ap-southeast-1')  # Replace 'ap-southeast-1' with your AWS region


def get_log_groups_with_prefix(prefix):
    """
    Get log groups that start with a specified prefix.
    """
    log_groups = []
    paginator = client.get_paginator('describe_log_groups')
    for page in paginator.paginate():
        for log_group in page['logGroups']:
            if not log_group['logGroupName'].startswith(prefix):
                print(log_group['logGroupName'])
                log_groups.append(log_group['logGroupName'])
    return log_groups


def update_log_group_tags(log_group_name, tags):
    """
    Update tags for a specific log group.
    """
    try:
        # Add or update tags for the log group
        client.tag_log_group(
            logGroupName=log_group_name,
            tags=tags
        )
        print(f"Tags updated successfully for log group '{log_group_name}'.")

    except Exception as e:
        print(f"Error updating tags for log group '{log_group_name}': {e}")


def main():
    # Define the prefix to filter log groups
    prefix = '/aws/lambda/awso2.10'  # Replace with your desired prefix

    # Define tags to update
    tags_to_update = {
        'username': 'akhil',
        'team': 'apps'
    }

    # Get log groups with the specified prefix
    log_groups = get_log_groups_with_prefix(prefix)
    print(f"Found log groups with prefix '{prefix}': {len(log_groups)}")

    # Update tags for each filtered log group
    for log_group_name in log_groups:
        update_log_group_tags(log_group_name, tags_to_update)


if __name__ == "__main__":
    main()
