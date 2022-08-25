data "archive_file" "lambda_source" {
  source_file      = "${path.module}/data/${local.name}.py"
  output_file_mode = "0666"
  output_path      = "${local.name}.zip"
  type             = "zip"
}

resource "aws_lambda_function" "lambda" {
  function_name    = local.name
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = data.archive_file.lambda_source.output_base64sha256

  handler = "${local.name}.lambda_handler"
  runtime = "python3.9"

  environment {
    variables = {
      LOG_LEVEL = "debug"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution_policy_attachement
    #aws_cloudwatch_log_group.task-creation,
  ]

  reserved_concurrent_executions = 1
  memory_size                    = 10240
  timeout                        = 900

  tags = local.tags
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012–10–17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_policy_attachement" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}