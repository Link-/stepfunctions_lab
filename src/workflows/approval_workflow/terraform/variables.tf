variable "aws_profile" {
  default     = "default"
  description = "AWS profile you'd like to use. Default = default"
}

variable "aws_region" {
  default     = "eu-west-1"
  description = "AWS region you'd like to create resources in. Default = eu-west-1"
}

variable "credentials_path" {
  default     = "~/.aws/credentials"
  description = "AWS credentials path. Default = ~/.aws/credentials"
}

variable "order_process_lambda_function_name" {
  default     = "PROCESS_ORDER"
  description = "Name of the order processing simulation's lambda"
}

variable "lambda_function_payload" {
  description = "Relative path of the backup simulation lambda payload"
}

variable "order_process_lambda_iam_role_name" {
  default     = "OrderProcessLambdaRole"
  description = "Name of the IAM role to be used for the order processing simulation lambda"
}

variable "sfn_state_machine_name" {
  default     = "ApprovalWorkflowStateMachine"
  description = "Name of the step functions state machine"
}

variable "sfn_state_machine_definition" {
  description = "Relative path of the step functions state machine definition"
}

variable "sfn_iam_role_name" {
  default     = "ApprovalWorkflowStepFunctionsRole"
  description = "Name of the IAM role used for the approval workflow state machine"
}

variable "api_gateway_order_process_api_name" {
  default     = "OrderProcessAPI"
  description = "Name of the API Gateway's API used to trigger a workflow execution"
}

variable "api_gateway_iam_role_name" {
  default     = "APIGatewayRole"
  description = "Name of the IAM role used by the API gateway to trigger new state machine executions"
}