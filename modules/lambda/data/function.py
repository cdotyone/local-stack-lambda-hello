import os
import logging
import boto3
import json

Logger = logging.getLogger()
Logger.setLevel(logging.INFO)

IS_PROD = os.environ['env'] == 'prod'

def get_s3_client():
    if IS_PROD:
        return boto3.resource('s3')
    else:
        return boto3.resource('s3', aws_access_key_id='', aws_secret_access_key='', region_name='us-east-2',endpoint_url='http://localhost:4566')


def lambda_handler(event_data, lambda_config):
    s3name = os.environ["bucket"]

    s3_resource = get_s3_client()
    bucket = s3_resource.Bucket(s3name)

    json_data = bucket.Object('countries.json').get()['Body'].read().decode('utf-8') 
    countries = json.loads(json_data)
    return countries

