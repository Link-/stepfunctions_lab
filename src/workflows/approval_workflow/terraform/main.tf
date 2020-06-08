# +---------------------------------+
# | Terraform                       |
# | +-----------------------------+ |
# |                                 |
# | Creates an AWS Step Functions   |
# | workflow to simulate an         |
# | approval process.               |
# |                                 |
# | Keep in mind the "systems" do   |
# | not exist, so this just is a    |
# | simulation.                     |
# |                                 |
# | MAKE SURE TO DESTROY THE        |
# | RESOURCES WHEN YOU'RE DONE      |
# | TO AVOID ACCUMULATING CHARGES   |
# |                                 |
# | v:0.1                           |
# +---------------------------------+

provider "aws" {
  profile                 = var.aws_profile
  region                  = var.aws_region
  shared_credentials_file = var.credentials_path
}

data "aws_region" "current" {}

# Used to be appended to all resources names to make the setup
# unique
resource "random_pet" "suffix" {
  length    = 2
  separator = "-"
}

# Messages pushed to SQS require a MessageGroupId parameter
resource "random_uuid" "sqs_mqid" {}

# Create a cloudwatch log group for the lambda
resource "aws_cloudwatch_log_group" "order_process_log" {
  name              = "/aws/lambda/${var.order_process_lambda_function_name}-${random_pet.suffix.id}"
  retention_in_days = 5
}

# Create the role that the lambda will assume
resource "aws_iam_role" "order_process_lambda" {
  name = "${var.order_process_lambda_iam_role_name}-${random_pet.suffix.id}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
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

# Create lambda policy to allow it to write to cloudwatch log groups
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging-${random_pet.suffix.id}"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Attach the policies to the lambda role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.order_process_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.order_process_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

# iam role for step functions
resource "aws_iam_role" "sfn_state_machine" {
  name = "${var.sfn_iam_role_name}-${random_pet.suffix.id}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.${data.aws_region.current.name}.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Policy allowing step functions to invoke lambdas
resource "aws_iam_policy" "sfn_lambda_invoke" {
  name        = "sfn_lambda_invoke-${random_pet.suffix.id}"
  path        = "/"
  description = "IAM policy for invoking a lambda from a step functions workflow"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Create lambda policy to allow it to push messages to SQS
resource "aws_iam_policy" "sfn_sqs" {
  name        = "sfn_sqs-${random_pet.suffix.id}"
  path        = "/"
  description = "IAM policy pushing messages to SQS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sfn_sqs" {
  role       = aws_iam_role.sfn_state_machine.name
  policy_arn = aws_iam_policy.sfn_sqs.arn
}

# Attach the policies to the step functions role
resource "aws_iam_role_policy_attachment" "lambda_invoke" {
  role       = aws_iam_role.sfn_state_machine.name
  policy_arn = aws_iam_policy.sfn_lambda_invoke.arn
}

# iam role for api gateway to start a state machine execution
resource "aws_iam_role" "api_gateway" {
  name = "${var.api_gateway_iam_role_name}-${random_pet.suffix.id}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Create an API Gateway policy to allow it to start a new state machine execution
resource "aws_iam_policy" "api_gateway_sfn" {
  name        = "api_gateway_sfn-${random_pet.suffix.id}"
  path        = "/"
  description = "IAM policy triggering state machine executions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "states:*",
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach the policies to the api gateway role
resource "aws_iam_role_policy_attachment" "api_gateway_sfn" {
  role       = aws_iam_role.api_gateway.name
  policy_arn = aws_iam_policy.api_gateway_sfn.arn
}

# Create the backup simulation lambda function to be used in the workflow
resource "aws_lambda_function" "order_process_lambda" {
  function_name = "${var.order_process_lambda_function_name}-${random_pet.suffix.id}"
  filename      = var.lambda_function_payload
  role          = aws_iam_role.order_process_lambda.arn
  handler       = "function.handler"

  source_code_hash = filebase64sha256("${var.lambda_function_payload}")
  runtime          = "python3.8"

  environment {
    variables = {
      ORDERS_QUEUE_URL = "${aws_sqs_queue.orders_queue.id}"
    }
  }

  depends_on = [
    aws_iam_role.order_process_lambda,
    aws_cloudwatch_log_group.order_process_log,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_execution,
    aws_sqs_queue.orders_queue
  ]
}

# Create the step functions' state machine
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.sfn_state_machine_name}-${random_pet.suffix.id}"
  role_arn = aws_iam_role.sfn_state_machine.arn

  definition = templatefile(var.sfn_state_machine_definition, {
    order_process_lambda_arn   = aws_lambda_function.order_process_lambda.arn,
    order_sqs_url              = aws_sqs_queue.orders_queue.id
    order_sqs_arn              = aws_sqs_queue.orders_queue.arn,
    order_sqs_message_group_id = random_uuid.sqs_mqid.result
  })

  depends_on = [
    aws_lambda_function.order_process_lambda,
    aws_iam_role.sfn_state_machine,
    aws_iam_role_policy_attachment.sfn_sqs,
    aws_iam_role_policy_attachment.lambda_invoke,
    aws_sqs_queue.orders_queue
  ]
}

# Create the queue to contain the orders pending approval / rejection
resource "aws_sqs_queue" "orders_queue" {
  name                        = "pending_orders_queue"
  fifo_queue                  = false
  content_based_deduplication = false
}

# Create the API gateway endpoint that will trigger the execution of a state machine
resource "aws_api_gateway_rest_api" "order_process" {
  name        = "${var.api_gateway_order_process_api_name}-${random_pet.suffix.id}"
  description = "Proxy to handle requests to our API"
}

resource "aws_api_gateway_resource" "order" {
  rest_api_id = aws_api_gateway_rest_api.order_process.id
  parent_id   = aws_api_gateway_rest_api.order_process.root_resource_id
  path_part   = "order"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.order_process.id
  resource_id   = aws_api_gateway_resource.order.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.order_process.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration_response" "sfn_response" {
  rest_api_id = aws_api_gateway_rest_api.order_process.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }
}

resource "aws_api_gateway_integration" "start_execution" {
  rest_api_id             = aws_api_gateway_rest_api.order_process.id
  resource_id             = aws_api_gateway_resource.order.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:states:action/StartExecution"
  credentials             = aws_iam_role.api_gateway.arn
}

resource "aws_api_gateway_deployment" "order_process" {
  rest_api_id = aws_api_gateway_rest_api.order_process.id
  stage_name  = "test"

  depends_on = [
    aws_api_gateway_integration.start_execution,
    aws_api_gateway_method_response.response_200,
    aws_api_gateway_integration_response.sfn_response
  ]
}

/**
 * Enable CORS on the APIs to allow calling them from the controller app
 * running locally
 */
module "cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.1"

  api_id            = aws_api_gateway_rest_api.order_process.id
  api_resource_id   = aws_api_gateway_resource.order.id
  allow_credentials = true
}