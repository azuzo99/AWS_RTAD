import json
import boto3

def lambda_handler(event, context):
   
    
    glue_client = boto3.client('glue')
    s3_client = boto3.client('s3')
    
    latest_versions = s3_client.list_object_versions(Bucket='glue-lambda-test-input-versioning')['Versions'][0:2]
    
    if len(latest_versions) > 1:
        version_id = latest_versions[1]['VersionId']
    elif len(latest_versions) == 1:
        version_id = latest_versions[0]['VersionId']
    else:
        version_id = None
    
    job_name = 'lambda-glue-pass'
    
    custom_args = {
    
    "--TRIGGER":"YES",
    "--version_tag":version_id
    }
    # No runs found, possibly a new job. Trigger it just in case.
    glue_client.start_job_run(JobName=job_name, Arguments=custom_args)
    print(f"Job {job_name} was triggered because it has no previous runs with custom arguments {custom_args}.")
    return {
    'statusCode': 200,
    'body': json.dumps('triggered with argument TRIGGERED = True')
    }
