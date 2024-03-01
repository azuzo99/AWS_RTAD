import json
import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
   
    
    glue_client = boto3.client('glue')
    s3_client = boto3.client('s3')
    cw_client = boto3.client('logs')
    
    latest_versions = s3_client.list_object_versions(Bucket=os.getenv('VERSIONED_BUCKET'))['Versions'][0:2]
    
    if len(latest_versions) > 1:
        version_id = latest_versions[1]['VersionId']
    elif len(latest_versions) == 1:
        version_id = latest_versions[0]['VersionId']
    else:
        version_id = None
    
    job_name = os.getenv('JOB_NAME')
    
    custom_args = {
    
    "--VERSION_TAG":version_id
    }
    
    glue_client.start_job_run(JobName=job_name, Arguments=custom_args)

    cw_client.put_log_events(
        logGroupName=os.getenv('LOG_GROUP_NAME'),
        logStreamName=os.getenv('LOG_STREAM_NAME'),
        logEvents=[
            {
                'timestamp': int(datetime.now().timestamp() * 1000),
                'message': f"Job {job_name} was triggered custom arguments {custom_args}.Based on bucket {os.getenv('VERSIONED_BUCKET')}"
            },
        ],
    )

    return {
    'statusCode': 200,
    'body': json.dumps('Triggered successfully!')
    }
