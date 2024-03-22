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

# DynamoDB
resource "aws_dynamodb_table" "tasks" {
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

# POST LAMBDA
resource "aws_lambda_function" "create_scheduled_task" {
  filename      = "${path.module}/../lambda/createScheduledTask.zip"
  function_name = "createScheduledTask"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "createScheduledTask.createScheduledTask"
  runtime       = "python3.8"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "DynamoDB"
    }
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/createScheduledTask.py"
  output_path = "${path.module}/../lambda/createScheduledTask.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = file("lambda-policy.json")
}

resource "aws_iam_policy_attachment" "lambda_dynamodb_access" {
  name       = "lambda-dynamodb-access"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# LAMBDA
resource "aws_lambda_function" "list_scheduled_task" {
  filename      = "${path.module}/../lambda/listScheduledTask.zip"
  function_name = "listScheduledTask"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "get.listScheduledTask"
  runtime       = "python3.8"
}

data "archive_file" "list_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/listScheduledTask.py"
  output_path = "${path.module}/../lambda/listScheduledTask.zip"
}

resource "aws_iam_policy" "list_lambda_policy" {
  name        = "list_lambda_policy"
  description = "Policy for Lambda function to read from DynamoDB"

  policy = file("scan-policy.json")
}

resource "aws_iam_role_policy_attachment" "list_lambda_policy_attachment" {
  policy_arn = aws_iam_policy.list_lambda_policy.arn
  role       = aws_iam_role.lambda_exec.name  # Corrected role name
}

# TASK API
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

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_scheduled_task.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = aws_api_gateway_rest_api.task_api.execution_arn
}

resource "aws_api_gateway_method" "list_task_method" {
  rest_api_id   = aws_api_gateway_rest_api.task_api.id
  resource_id   = aws_api_gateway_resource.list_task_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_task_integration" {
  rest_api_id             = aws_api_gateway_rest_api.task_api.id
  resource_id             = aws_api_gateway_resource.create_task_resource.id
  http_method             = aws_api_gateway_method.create_task_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_scheduled_task.invoke_arn
}

resource "aws_api_gateway_integration" "list_task_integration" {
  rest_api_id             = aws_api_gateway_rest_api.task_api.id
  resource_id             = aws_api_gateway_resource.list_task_resource.id
  http_method             = aws_api_gateway_method.list_task_method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_scheduled_task.invoke_arn
}
