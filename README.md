# local-stack-http-gateway

## Credentials
Need to add contents of "credentials" file to your .aws/credentials file.  In your profile folder.  So for windows /users/&lt;your login&gt;/.aws/credentials

## Dependencies
Need to have docker, python and terraform installed

## Initialization
In a terminal or powershell from this project folder run:

```
docker-compose up
```

in another terminal or powershell run:

```
terraform init
terraform apply
```

## Test
To see if we have data after terraform created dynamodb table and then loaded it with data using python
```
python ./query.py
```

Test simple list countries

```
aws --endpoint-url=http://localhost:4566 lambda invoke --function dyna-country --payload '{}' lambda.out
```