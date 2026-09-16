import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    task_id = event['pathParameters']['id']

    response = table.get_item(Key={'id': task_id})

    if 'Item' not in response:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Task not found'})
        }

    return {
        'statusCode': 200,
        'body': json.dumps(response['Item'])
    }