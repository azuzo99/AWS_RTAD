import json
import boto3
import os

def lambda_handler(event, context):
   
    
    glue_client = boto3.client('glue')
    s3_client = boto3.client('s3')
    
    latest_versions = s3_client.list_object_versions(Bucket=os.getenv('versioned_bucket'))['Versions'][0:2]
    
    if len(latest_versions) > 1:
        version_id = latest_versions[1]['VersionId']
    elif len(latest_versions) == 1:
        version_id = latest_versions[0]['VersionId']
    else:
        version_id = None
    
    job_name = os.getenv('job_name')
    
    custom_args = {
    
    "--TRIGGER":"YES",
    "--version_tag":version_id
    }
    # glue_client.start_job_run(JobName=job_name, Arguments=custom_args)
    print(f"Job {job_name} was triggered custom arguments {custom_args}.Based on bucket {os.getenv('versioned_bucket')}")
    return {
    'statusCode': 200,
    'body': json.dumps('triggered with argument TRIGGERED = True')
    }
