# lambda_function.py
import boto3
import datetime
import os
import logging
import json
from zoneinfo import ZoneInfo

logger = logging.getLogger()
logger.setLevel(logging.INFO)
ec2 = boto3.client('ec2')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    # INSTANCE_ID = 'i-xxxxxxxxxxxxxxxxx'
    # instances = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
    asg_name = os.getenv('ASG_NAME','yoobee-web-asg') 
    bucket_name= os.getenv('BUCKET_NAME')
    filters = [
        {
            'Name': 'tag:aws:autoscaling:groupName',
            'Values': [asg_name]  # This Name should match the name created in terraform
        },
        {
            'Name': 'instance-state-name',
            'Values': ['running']
        }
    ]
    try:
        instances = ec2.describe_instances(Filters=filters)
        #Take snapshots one by one
        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                for device in instance['BlockDeviceMappings']:
                    volume_id = device['Ebs']['VolumeId']
                    nz_time = datetime.datetime.now(ZoneInfo("Pacific/Auckland"))
                    timestamp = nz_time.strftime('%Y-%m-%d-%H-%M')
                    description = f"Backup of {volume_id} from {instance_id} on {timestamp}"

                    logger.info(f"Creating snapshot for volume: {volume_id}")
                    snapshot = ec2.create_snapshot(
                        VolumeId=volume_id,
                        Description=description,
                        TagSpecifications=[{
                            'ResourceType':'snapshot',
                            'Tags':[
                                {'Key': 'Name', 'Value': f"{instance_id}-backup"},
                                {'Key': 'CreatedBy', 'Value': 'LambdaDailyBackup'},
                                {'Key': 'Date', 'Value': timestamp}
                            ]
                        }]
                    )
                    snapshot_id = snapshot['SnapshotId']
                    logger.info(f"Snapshot created: {snapshot_id}")

                    ###########SAVE meta data to our bucket
                    # Prepare metadata
                    metadata = {
                        'SnapshotId': snapshot_id,
                        'VolumeId': volume_id,
                        'InstanceId': instance_id,
                        'Description': description,
                        'Timestamp': timestamp
                    }

                    # Convert metadata to JSON
                    metadata_json = json.dumps(metadata, indent=4)

                    # Define S3 object key (filename) with date folder
                    s3_key = f"snapshot_metadata/{timestamp}/{snapshot_id}.json"

                    # Upload metadata file to S3
                    s3.put_object(
                        Bucket=bucket_name,
                        Key=s3_key,
                        Body=metadata_json,
                        ContentType='application/json'
                    )

                    logger.info(f"Snapshot metadata saved to s3://{bucket_name}/{s3_key}")
    except Exception as e:
        logger.error(f"Error occured: {str(e)}")
        raise
