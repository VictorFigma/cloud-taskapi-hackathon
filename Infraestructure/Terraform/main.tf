# Config
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    events         = "http://localhost:4566"
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
    s3             = "http://localhost:4566"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "taskstorage" {
  bucket = "taskstorage"

  tags = {
    Name = "taskstorage"
  }
}

# DynamoDB
resource "aws_dynamodb_table" "DynamoDB" {
  name           = "DynamoDB"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "task_id"

  attribute {
    name = "task_id"
    type = "S"
  }

  attribute {
    name = "task_name"
    type = "S"
  }

  attribute {
    name = "cron_expression"
    type = "S"
  }

  global_secondary_index {
    name               = "TaskNameIndex"
    hash_key           = "task_name"
    projection_type    = "ALL"
    read_capacity      = 1
    write_capacity     = 1
  }

  global_secondary_index {
    name               = "CronExpressionIndex"
    hash_key           = "cron_expression"
    projection_type    = "ALL"
    read_capacity      = 1
    write_capacity     = 1
  }
}

# Data zip
data "archive_file" "create_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/createScheduledTask.py"
  output_path = "${path.module}/../lambda/createScheduledTask.zip"
}

data "archive_file" "list_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/listScheduledTask.py"
  output_path = "${path.module}/../lambda/listScheduledTask.zip"
}

data "archive_file" "execute_lambda_zip" {
  type        = "zip"
  source_file =  "${path.module}/../lambda/executeScheduledTask.py"
  output_path =  "${path.module}/../lambda/executeScheduledTask.zip"
}

# Lambdas
resource "aws_lambda_function" "create_scheduled_task" {
  filename      = "${path.module}/../lambda/createScheduledTask.zip"
  function_name = "createScheduledTask"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "createScheduledTask.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "DynamoDB"
    }
  }
}

resource "aws_lambda_function" "list_scheduled_task" {
  filename      = "${path.module}/../lambda/listScheduledTask.zip"
  function_name = "listScheduledTask"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "listScheduledTask.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_lambda_function" "execute_scheduled_task" {
  filename      = "${path.module}/../lambda/executeScheduledTask.zip"
  function_name = "executeScheduledTask"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "executeScheduledTask.lambda_handler"
  runtime       = "python3.8"
}

# IAM
resource "aws_iam_role" "lambda_exec" {
  name               = "lambda_exec_role"
  assume_role_policy = file("${path.module}/lambda-policy.json")
}

resource "aws_iam_policy" "lambda_policy_db_access" {
  name        = "lambda_policy_db_access"
  description = "Policy for Lambda function to interact with DynamoDB"
  policy      = file("${path.module}/put-policy.json")
}

resource "aws_iam_policy" "list_lambda_policy" {
  name        = "list_lambda_policy"
  description = "Policy for Lambda function to read from DynamoDB"
  policy      = file("${path.module}/scan-policy.json")
}

resource "aws_iam_policy" "execute_lambda_policy" {
  name        = "execute_lambda_policy"
  description = "Policy for Lambda function to write to S3"
  policy      = file("${path.module}/event-policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy_db_access.arn
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_role_policy_attachment" "list_lambda_policy_attachment" {
  policy_arn = aws_iam_policy.list_lambda_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_role_policy_attachment" "execute_lambda_policy_attachment" {
  policy_arn = aws_iam_policy.execute_lambda_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

# CloudWatch
resource "aws_cloudwatch_event_rule" "every_minute_rule" {
  name                = "every-minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_lambda_permission" "eventbridge_lambda_permission" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.execute_scheduled_task.arn
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_target" "execute_scheduled_task_target" {
  rule = aws_cloudwatch_event_rule.every_minute_rule.name
  arn  = aws_lambda_function.execute_scheduled_task.arn
}

# API Gateway
resource "aws_api_gateway_rest_api" "task_api" {
  name        = "TaskAPI"
  description = "API Gateway for TaskAPI"
}

resource "aws_api_gateway_resource" "create_task_resource" {
  rest_api_id = aws_api_gateway_rest_api.task_api.id
  parent_id   = aws_api_gateway_rest_api.task_api.root_resource_id
  path_part   = "createtask"
}

resource "aws_api_gateway_resource" "list_task_resource" {
  rest_api_id = aws_api_gateway_rest_api.task_api.id
  parent_id   = aws_api_gateway_rest_api.task_api.root_resource_id
  path_part   = "listtask"
}

resource "aws_api_gateway_method" "create_task_method" {
  rest_api_id   = aws_api_gateway_rest_api.task_api.id
  resource_id   = aws_api_gateway_resource.create_task_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "list_task_method" {
  rest_api_id   = aws_api_gateway_rest_api.task_api.id
  resource_id   = aws_api_gateway_resource.list_task_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_lambda_permission" "apigw_create_task_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_scheduled_task.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.task_api.execution_arn}/POST/createtask"
}

resource "aws_lambda_permission" "apigw_list_task_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_scheduled_task.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.task_api.execution_arn}/GET/listtask"
}

resource "aws_api_gateway_integration" "create_task_integration" {
  rest_api_id             = aws_api_gateway_rest_api.task_api.id
  resource_id             = aws_api_gateway_resource.create_task_resource.id
  http_method             = aws_api_gateway_method.create_task_method.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  uri                     = "http://localhost:4566/createtask"
}

resource "aws_api_gateway_integration" "list_task_integration" {
  rest_api_id             = aws_api_gateway_rest_api.task_api.id
  resource_id             = aws_api_gateway_resource.list_task_resource.id
  http_method             = aws_api_gateway_method.list_task_method.http_method
  integration_http_method = "GET"
  type                    = "HTTP"
  uri                     = "http://localhost:4566/listtask"
}