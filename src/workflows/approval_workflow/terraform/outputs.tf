output "order_process_lambda_arn" {
  value = aws_lambda_function.order_process_lambda.arn
}

output "sfn_state_machine_arn" {
  value = aws_sfn_state_machine.sfn_state_machine.id
}

output "orders_queue_sqs_url" {
  value = aws_sqs_queue.orders_queue.id
}