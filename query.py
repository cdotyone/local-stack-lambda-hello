import os
import logging
import boto3
from boto3.dynamodb.conditions import Key
import json

Logger = logging.getLogger()
Logger.setLevel(logging.INFO)

IS_PROD = os.environ.get('env','local') == 'prod'

def get_dynamodb_resource():
    if IS_PROD:
        return boto3.resource('dynamodb')
    else:
        return boto3.resource('dynamodb', aws_access_key_id='test', aws_secret_access_key='test', region_name='us-east-2',endpoint_url='http://localhost:4566')

db = get_dynamodb_resource()
table = db.Table('countries')

def getCountry(code):
    response = table.query(
        KeyConditionExpression = Key('countryCode').eq(code)
    )
    data = response['Items']

    return data[0]


def getCountries():
    response = table.scan()
    data = response['Items']

    while 'LastEvaluatedKey' in response:
        response = table.query(ExclusiveStartKey=response['LastEvaluatedKey'])
        data.extend(response['Items'])
    
    return data

us = getCountry('US')

print("\nUnited States\n")
print(us)

print("\nAll\n")
print(getCountries())