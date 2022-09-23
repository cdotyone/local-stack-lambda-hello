terraform {
  backend "local" {}
}

# Public Cloud Configuration
provider "aws" {
  region     = "us-east-2"
  access_key = "fake"
  secret_key = "fake"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigatewayv2   = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://LOCALHOST:4566"
    s3             = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    ec2            = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "b" {
  bucket = "localstack-s3-dynamo"
  tags   = var.tags
}

resource "aws_dynamodb_table" "countries_table" {
  name           = "countries"
  billing_mode   = "PROVISIONED"
  read_capacity  = "30"
  write_capacity = "30"
  attribute {
    name = "countryCode"
    type = "S"
  }
  attribute {
    name = "name"
    type = "S"
  }

  hash_key  = "countryCode"
  range_key = "name"

  provisioner "local-exec" {
    command = "python load.py"
  }
}

module "lambda_country" {
  source = "./modules/lambda"
  name   = "dyna-country"
  environment = {
    env = var.tags.env
  }
  tags = var.tags
}

resource "aws_route53_zone" "main" {
  name = "demo.local"
}

# API Gateway
resource "aws_apigatewayv2_api" "apigw" {
  name          = "apidemo"
  description   = "My HTTP API Gateway"
  protocol_type = "HTTP"

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.apigw.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "country" {
  api_id             = aws_apigatewayv2_api.apigw.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = module.lambda_country.invoke_arn

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "list_route" {
  api_id           = aws_apigatewayv2_api.apigw.id
  route_key        = "ANY /country"
  api_key_required = false
  operation_name   = "list"
  target           = "integrations/${aws_apigatewayv2_integration.country.id}"
}

resource "aws_lambda_permission" "api-gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_country.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apigw.execution_arn}/*/*/*"
}


/*
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "demo.local"
  type    = "A"

  alias {
    name                   = module.api_gateway.apigatewayv2_domain_name_configuration[0].target_domain_name
    zone_id                = module.api_gateway.apigatewayv2_domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
*/