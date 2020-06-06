output "backup_lambda_arn" {
  value = aws_lambda_function.backup_lambda.arn
}

output "sfn_state_machine_arn" {
  value = aws_sfn_state_machine.sfn_state_machine.id
}