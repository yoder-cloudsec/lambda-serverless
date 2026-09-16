import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    response = table.scan()

    return {
        'statusCode': 200,
        'body': json.dumps(response['Items'])
    }