import boto3

# Initialize CloudWatch Logs client
client = boto3.client('logs', region_name='ap-southeast-1')  # Replace 'us-east-1' with your AWS region


def get_log_groups_without_tags():
    """
    Get log groups that have no tags.
    """
    log_groups_without_tags = []
    paginator = client.get_paginator('describe_log_groups')

    # Paginate through all log groups
    for page in paginator.paginate():
        for log_group in page['logGroups']:
            log_group_name = log_group['logGroupName']

            # Get tags for each log group
            response = client.list_tags_log_group(logGroupName=log_group_name)
            tags = response.get('tags', {})
            # Check if the log group has no tags
            if not tags:
                print("log_group_name", log_group_name, 'tags', tags)
                log_groups_without_tags.append(log_group_name)

    return log_groups_without_tags


def main():
    # Get log groups without any tags
    log_groups = get_log_groups_without_tags()

    if log_groups:
        print("Log groups without any tags:")
        for log_group in log_groups:
            print(f"- {log_group}")
    else:
        print("All log groups have tags.")


if __name__ == "__main__":
    main()
