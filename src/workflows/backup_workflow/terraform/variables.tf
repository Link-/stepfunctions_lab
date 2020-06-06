variable "backup_lambda_iam_role_name" {
  default     = "BackupLambdaDemoRole"
  description = "Name of the IAM role to be used for the backup simulation lambda"
}

variable "backup_lambda_function_name" {
  default     = "BACKUP_SIMULATION"
  description = "Name of the backup simulation lambda"
}

variable "lambda_function_payload" {
  description = "Relative path of the backup simulation lambda payload"
}

variable "sfn_iam_role_name" {
  default     = "BackupStepFunctionsRole"
  description = "Name of the IAM role used for the backup state machine"
}

variable "sfn_state_machine_definition" {
  description = "Relative path of the step functions state machine definition"
}

variable "sfn_state_machine_name" {
  default     = "BackupStateMachine"
  description = "Name of the step functions state machine"
}