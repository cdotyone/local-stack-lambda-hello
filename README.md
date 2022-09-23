# local-stack-lambda-s3

## Credentials
Need to add contents of "credentials" file to your .aws/credentials file.  In your profile folder.  So for windows /users/&lt;your login&gt;/.aws/credentials

## Dependencies
Need to have docker, python and terraform installed

## Initialization
In a terminal or powershell from this project folder run:

```
docker-compose up
```

In another terminal or powershell run:

```
terraform init
terraform apply
```

## Test
To see the lambda run run 

```
aws --endpoint-url=http://localhost:4566 lambda invoke --function s3lambda --payload '{}' lambda.out
```
