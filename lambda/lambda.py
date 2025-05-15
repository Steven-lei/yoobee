# lambda_function.py
import boto3
import datetime

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    filters = [
        {
            'Name': 'tag:aws:autoscaling:groupName',
            'Values': ['yoobee-web-asg']  # This Name should match the name created in terraform
        },
        {
            'Name': 'instance-state-name',
            'Values': ['running']
        }
    ]

    instances = ec2.describe_instances(Filters=filters)
    
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            for device in instance['BlockDeviceMappings']:
                volume_id = device['Ebs']['VolumeId']
                timestamp = datetime.datetime.utcnow().strftime('%Y-%m-%d-%H-%M')
                description = f"Backup of {volume_id} from {instance_id} on {timestamp}"

                snapshot = ec2.create_snapshot(
                    VolumeId=volume_id,
                    Description=description
                )

                ec2.create_tags(
                    Resources=[snapshot['SnapshotId']],
                    Tags=[
                        {'Key': 'Name', 'Value': f"{instance_id}-backup"},
                        {'Key': 'CreatedBy', 'Value': 'LambdaDailyBackup'},
                        {'Key': 'Date', 'Value': timestamp}
                    ]
                )
