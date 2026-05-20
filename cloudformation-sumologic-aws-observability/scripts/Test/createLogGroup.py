import boto3
import uuid

# Initialize a session using Amazon CloudWatch
client = boto3.client('logs')

prefix = '/aws/lambda/awso2.10'
number_of_groups = 8000


def create_log_groups(prefix, number_of_groups):
    for i in range(number_of_groups):
        unique_id = uuid.uuid4()
        log_group_name = f"{prefix}-{unique_id}"
        tags = {
            'team': 'apps',
            'username': 'akhil'
        }
        try:
            response = client.create_log_group(
                logGroupName=log_group_name,

            )
            print(f"Created log group: {log_group_name}")
        except client.exceptions.ResourceAlreadyExistsException:
            print(f"Log group already exists: {log_group_name}")
        except Exception as e:
            print(f"Error creating log group {log_group_name}: {e}")


if __name__ == "__main__":
    create_log_groups(prefix, number_of_groups)
