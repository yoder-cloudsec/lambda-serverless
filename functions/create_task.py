import json
import boto3
import uuid
import os
import base64

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    raw_body = event['body']
    if event.get('isBase64Encoded'):
        raw_body = base64.b64decode(raw_body).decode('utf-8')

    body = json.loads(raw_body)

    task = {
        'id': str(uuid.uuid4()),
        'title': body['title'],
        'completed': False
    }

    table.put_item(Item=task)

    return {
        'statusCode': 201,
        'body': json.dumps(task)
    }