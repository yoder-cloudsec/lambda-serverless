import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    task_id = event['pathParameters']['id']

    table.delete_item(Key={'id': task_id})

    return {
        'statusCode': 204,
        'body': ''
    }