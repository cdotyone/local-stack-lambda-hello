# local-stack-lambda-hello

## Credentials
Need to add contents of "credentials" file to your .aws/credentials file.  In your profile folder.  So for windows /users/<your login>/.aws/credentials

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
To see the lambda run run 

```
aws --endpoint-url=http://localhost:4566 lambda invoke --function hello --payload '{}' lambda.out
```
