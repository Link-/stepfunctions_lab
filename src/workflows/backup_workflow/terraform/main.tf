# +---------------------------------+
# | Terraform                       |
# | +-----------------------------+ |
# |                                 |
# | Creates an AWS Step Functions   |
# | workflow to take scheduled      |
# | backups of some system and      |
# | store them in an S3 bucket.     |
# |                                 |
# | Keep in mind the "system" does  |
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

resource "random_pet" "suffix" {
  length    = 2
  separator = "-"
}

# Create a cloudwatch log group for the lambda
resource "aws_cloudwatch_log_group" "backup_log" {
  name              = "/aws/lambda/${var.backup_lambda_function_name}-${random_pet.suffix.id}"
  retention_in_days = 5
}

# Create the role that the lambda will assume
resource "aws_iam_role" "backup_lambda" {
  name = "${var.backup_lambda_iam_role_name}-${random_pet.suffix.id}"

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

# iam role for cloud watch to trigger step function state machine
resource "aws_iam_role" "cloud_watch" {
  name = "${var.cloudwatch_iam_role_name}-${random_pet.suffix.id}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Policy allowing cloudwatch to trigger step function state machines
resource "aws_iam_policy" "cloudwatch_sfn_trigger" {
  name        = "cloudwatch_sfn_trigger-${random_pet.suffix.id}"
  path        = "/"
  description = "IAM policy for invoking step functions state machines"

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
  role       = aws_iam_role.backup_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.backup_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

# Attach the policies to the step functions role
resource "aws_iam_role_policy_attachment" "lambda_invoke" {
  role       = aws_iam_role.sfn_state_machine.name
  policy_arn = aws_iam_policy.sfn_lambda_invoke.arn
}

# Attach the policies to cloudwatch role
resource "aws_iam_role_policy_attachment" "cloudwatch_trigger_sfn" {
  role       = aws_iam_role.cloud_watch.name
  policy_arn = aws_iam_policy.cloudwatch_sfn_trigger.arn
}

# Create the backup simulation lambda function to be used in the workflow
resource "aws_lambda_function" "backup_lambda" {
  function_name = "${var.backup_lambda_function_name}-${random_pet.suffix.id}"
  filename      = var.lambda_function_payload
  role          = aws_iam_role.backup_lambda.arn
  handler       = "function.handler"

  source_code_hash = filebase64sha256("${var.lambda_function_payload}")
  runtime          = "python3.8"

  depends_on = [
    aws_iam_role.backup_lambda,
    aws_cloudwatch_log_group.backup_log,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_execution
  ]
}

# Create the step functions' state machine
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.sfn_state_machine_name}-${random_pet.suffix.id}"
  role_arn = aws_iam_role.sfn_state_machine.arn

  definition = templatefile(var.sfn_state_machine_definition, {
    backup_lambda_arn = aws_lambda_function.backup_lambda.arn
  })

  depends_on = [
    aws_lambda_function.backup_lambda,
    aws_iam_role.sfn_state_machine,
    aws_iam_role_policy_attachment.lambda_invoke
  ]
}

# Add cloudwatch event rule to schedule the execution of the workflow
# every 5 minutes
resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "${var.cloudwatch_event_rule_name}-${random_pet.suffix.id}"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "backup_every_five_minutes" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "execute_backup_workflow"
  role_arn  = aws_iam_role.cloud_watch.arn
  arn       = aws_sfn_state_machine.sfn_state_machine.id

  depends_on = [
    aws_sfn_state_machine.sfn_state_machine,
    aws_iam_role.cloud_watch,
    aws_iam_role_policy_attachment.cloudwatch_trigger_sfn
  ]
}
