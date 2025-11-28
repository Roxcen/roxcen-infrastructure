# Output values for EmailSMS API-Only Serverless Infrastructure

output "api_url" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.emailsms.invoke_url
}

output "api_gateway_url" {
  description = "API Gateway endpoint URL (alias for compatibility)"
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

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups"
  value = {
    api_gateway = aws_cloudwatch_log_group.api_logs.name
    lambda_api  = "/aws/lambda/${aws_lambda_function.emailsms_api.function_name}"
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
