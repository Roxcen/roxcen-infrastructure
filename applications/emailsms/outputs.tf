output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.emailsms.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.emailsms.id
}

output "lambda_api_function_name" {
  description = "Lambda API function name"
  value       = aws_lambda_function.emailsms_api.function_name
}

output "lambda_worker_function_name" {
  description = "Lambda worker function name"
  value       = aws_lambda_function.emailsms_worker.function_name
}

output "email_queue_url" {
  description = "SQS Email queue URL"
  value       = aws_sqs_queue.email_queue.url
}

output "sms_queue_url" {
  description = "SQS SMS queue URL"
  value       = aws_sqs_queue.sms_queue.url
}

output "email_dlq_url" {
  description = "Email Dead Letter Queue URL"
  value       = aws_sqs_queue.email_dlq.url
}

output "sms_dlq_url" {
  description = "SMS Dead Letter Queue URL"
  value       = aws_sqs_queue.sms_dlq.url
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups"
  value = {
    api_gateway = aws_cloudwatch_log_group.api_logs.name
    lambda_api  = aws_cloudwatch_log_group.lambda_api_logs.name
    lambda_worker = aws_cloudwatch_log_group.lambda_worker_logs.name
  }
}

output "service_url" {
  description = "Service URL (custom domain or API Gateway)"
  value = var.domain_name != "" ? "https://${var.domain_name}" : aws_apigatewayv2_stage.emailsms.invoke_url
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_role.arn
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment = var.environment
    region     = var.aws_region
    project    = var.project_name
    service    = "EmailSMS-Serverless"
    api_url    = aws_apigatewayv2_stage.emailsms.invoke_url
  }
}
