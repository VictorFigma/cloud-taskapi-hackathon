import boto3
import json
from datetime import datetime

s3 = boto3.client('s3', endpoint_url='http://localhost:4566')

def executeScheduledTask(event, context):
    bucket_name = 'taskstorage'
    object_key = f"task_{datetime.now().strftime('%Y-%m-%d_%H-%M')}.txt"
    s3.put_object(Bucket=bucket_name, Key=object_key, Body="New task created")

    return {
        'statusCode': 200,
        'body': json.dumps({'message': f'New task object created: s3://{bucket_name}/{object_key}'})
    }