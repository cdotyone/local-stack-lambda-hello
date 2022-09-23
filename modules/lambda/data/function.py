import os
import logging
import boto3
import json
from boto3.dynamodb.conditions import Key

Logger = logging.getLogger()
Logger.setLevel(logging.INFO)

IS_PROD = os.environ.get('env','local') == 'prod'

def get_dynamodb_resource():
    if IS_PROD:
        return boto3.resource('dynamodb')
    else:
        return boto3.resource('dynamodb', aws_access_key_id='test', aws_secret_access_key='test', region_name='us-east-2',endpoint_url='http://localhost:4566')

def getCountries(table):
    try: 
        response = table.scan()
        data = response['Items']

        while 'LastEvaluatedKey' in response:
            response = table.query(ExclusiveStartKey=response['LastEvaluatedKey'])
            data.extend(response['Items'])
        
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(data)
        }
    except:
        return badRequest()


def getCountry(table, code):
    response = table.query(
        KeyConditionExpression = Key('countryCode').eq(code)
    )
    data = response['Items']

    if len(data)==0:
        return None 

    return data[0]

def deleteCountry(table, code):
    try:

        response = "not assigned"
        response = table.delete_item(
            KeyConditionExpression = Key('countryCode').eq(code)
        )
        return {
                    "statusCode": "500",
                    "headers": {
                        "Content-Type": "application/json"
                    },
                    "body": "hello1"
                }
    except:
        return {
                    "statusCode": "200",
                    "headers": {
                        "Content-Type": "application/json"
                    },
                    "body":  "hello2"
                }        
        #return serverError()


def badRequest():
    return {
        "statusCode": 400,
        "body": "Bad Request"
    }
    
def notFound():
    return {
        "statusCode": 404,
        "body": "Not Found"
    }

def serverError():
    return {
        "statusCode": 500,
        "body": "Application error"
    }    

def lambda_handler(event_data, lambda_config):
    db = get_dynamodb_resource()
    table = db.Table('countries')

    method = event_data["requestContext"]["http"]["method"].upper()

    if method=="GET":
        try: 
            code = event_data["rawPath"].lstrip('/').split('/')[1].upper()
        except:
            return getCountries(table)

        # GET
        try: 
            country = getCountry(table, code)
            
            if country == None:
                return notFound()
        except:
            return serverError()

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(country)
        }
    

    if method=="POST":
        #DO ADD
        return badRequest()

    if method=="PUT":
        #DO UPDATE
        return badRequest()

    if method=="DELETE":
        #DO DELETE

        #try: 
            code = event_data["rawPath"].lstrip('/').split('/')[1].upper()
            return deleteCountry(table,code)
        #except:
        #    return badRequest()


    return badRequest()

