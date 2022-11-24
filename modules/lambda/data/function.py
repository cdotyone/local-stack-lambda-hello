import os
import logging
import boto3
import json
from boto3.dynamodb.conditions import Key

Logger = logging.getLogger()
Logger.setLevel(logging.INFO)

IS_PROD = os.environ.get('env','local') == 'prod'

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


def alreadyExists():
    return {
        "statusCode": 409,
        "body": "Already Exists"
    }

def serverError():
    return {
        "statusCode": 500,
        "body": "Application error"
    }    

def appError(message):
    return {
        "statusCode": 500,
        "body": message
    }      

def get_update_params(body, keys):
    #  FROM https://stackoverflow.com/questions/34447304/example-of-update-item-in-dynamodb-boto3
    update_expression = ["set "]
    update_values = dict()

    for key, val in body.items():
        if key in keys:
            continue
        update_expression.append(f" {key} = :{key},")
        update_values[f":{key}"] = val

    return "".join(update_expression)[:-1], update_values

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
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin" : "*"
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
    country = getCountry(table, code)

    if country == None:
        return notFound()

    response = table.delete_item(
        Key={
            "countryCode":code,
            "name": country["name"]
        }
    )

    if response['ResponseMetadata']['HTTPStatusCode']!=200:
        return {
            "statusCode": 500,
            "body": json.dumps(response['ResponseMetadata'])
        } 

    return {
            "statusCode": 200,
            "body": "OK"
    } 

def updateCountry(table, code, country):
    existingCountry = getCountry(table, code)

    if existingCountry == None:
        return notFound()

    a, v = get_update_params(country, ["countryCode","name"])

    response = table.update_item(
        Key={
            "countryCode":code,
            "name": country["name"]
        },
        UpdateExpression=a,
        ExpressionAttributeValues=dict(v)
    )

    if response['ResponseMetadata']['HTTPStatusCode']!=200:
        return {
            "statusCode": 500,
            "body": json.dumps(response['ResponseMetadata'])
        } 

    return {
            "statusCode": 200,
            "body": "OK"
    }    
     


def addCountry(table, country):
    existingCountry = getCountry(table, country["countryCode"])

    if existingCountry != None:
        return alreadyExists()

    response = table.put_item(
        Item=country
    )

    if response['ResponseMetadata']['HTTPStatusCode']!=200:
        return {
            "statusCode": 500,
            "body": json.dumps(response['ResponseMetadata'])
        } 

    return {
            "statusCode": 200,
            "body": "OK"
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
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin" : "*"
            },
            "body": json.dumps(country)
        }
    

    if method=="POST":
        #DO ADD
        return addCountry(table, json.loads(event_data["body"]))

    if method=="PUT":
        #DO UPDATE
        try: 
            code = event_data["rawPath"].lstrip('/').split('/')[1].upper()
        except:
            return badRequest()
        return updateCountry(table, code, json.loads(event_data["body"]))

    if method=="DELETE":
        #DO DELETE
        try: 
            code = event_data["rawPath"].lstrip('/').split('/')[1].upper()
        except:
            return badRequest()
        return deleteCountry(table, code)


    return badRequest()

