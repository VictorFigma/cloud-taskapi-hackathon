import json
import boto3

ddb = boto3.resource('dynamodb', endpoint_url='http://localhost:4566')
table = ddb.Table('DynamoDB')

def listScheduledTask(event, context):
    response = table.scan()
    items = response.get('Items', [])

    task_list = [{'task_id': item['task_id'], 'task_name': item['task_name'], 'cron_expression': item['cron_expression']} for item in items]

    return {
        'statusCode': 200,
        'body': json.dumps(task_list)
    }