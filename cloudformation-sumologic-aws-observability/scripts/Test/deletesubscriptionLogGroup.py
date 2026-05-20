import boto3

# Initialize a session using Amazon CloudWatch Logs
client = boto3.client('logs')

# Prefix of the log groups to unsubscribe from
log_group_prefix = '/aws/lambda/Ak'


# Function to delete subscription filters
def delete_subscription_filters(log_group_name):
    filters_response = client.describe_subscription_filters(logGroupName=log_group_name)
    print('filters_response', filters_response)
    filters = filters_response.get('subscriptionFilters', [])
    for subscription_filter in filters:
        filter_name = subscription_filter.get('filterName')
        client.delete_subscription_filter(logGroupName=log_group_name, filterName=filter_name)
        print(f"Deleted subscription filter '{filter_name}' from log group '{log_group_name}'")


if __name__ == "__main__":
    # List all log groups with the specified prefix
    response = client.describe_log_groups(logGroupNamePrefix=log_group_prefix)
    log_groups = response.get('logGroups', [])
    print(len(log_groups))

    # Loop through the log groups and delete subscription filters
    for log_group in log_groups:
        log_group_name = log_group.get('logGroupName')
        print('log_group_name', log_group_name)
        delete_subscription_filters(log_group_name)

    print("Unsubscribed from all log groups with the specified prefix.")
