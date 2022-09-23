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

def loadCountries(table):
    with open('countries.json', "r", encoding='utf-8') as f:
        lines = f.readlines()

    countries = json.loads(''.join(lines))
    for c in countries:
        if c.get('countryCode'):
            table.put_item(Item = c)

loadCountries(table)

