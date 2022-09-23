import os
import logging
import boto3
from boto3.dynamodb.conditions import Key

Logger = logging.getLogger()
Logger.setLevel(logging.INFO)

IS_PROD = os.environ.get('env','local') == 'prod'

def get_dynamodb_resource():
    if IS_PROD:
        return boto3.resource('dynamodb')
    else:
        return boto3.resource('dynamodb', aws_access_key_id='test', aws_secret_access_key='test', region_name='us-east-2',endpoint_url='http://localhost:4566')


def getCountry(table, code):
    response = table.query(
        KeyConditionExpression = Key('countryCode').eq(code)
    )
    data = response['Items']

    return data[0]

def lambda_handler(event_data, lambda_config):
    db = get_dynamodb_resource()
    table = db.Table('countries')

    us = getCountry(table,'US')
    return us
