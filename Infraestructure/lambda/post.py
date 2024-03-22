import json
import boto3
import uuid

ddb = boto3.resource('dynamodb', endpoint_url='http://localhost:4566')
table = ddb.Table('task_db')

def createScheduledTask(event, context):
    data = json.loads(event['body'])
    task_name = data.get('task_name')
    cron_expression = data.get('cron_expression')

    if not task_name or not cron_expression:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing task_name or cron_expression'})
        }

    task_id = str(uuid.uuid4())

    table.put_item(
        Item={
            'task_id': task_id,
            'task_name': task_name,
            'cron_expression': cron_expression
        }
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'task_id': task_id})
    }