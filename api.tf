resource "aws_apigatewayv2_api" "tasks_api" {
  name = "tasks-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.tasks_api.id
  name = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "create_task" {
  api_id = aws_apigatewayv2_api.tasks_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.create_task.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_task" {
  api_id = aws_apigatewayv2_api.tasks_api.id
  route_key = "POST /tasks"
  target = "integrations/${aws_apigatewayv2_integration.create_task.id}"
}

resource "aws_lambda_permission" "api_gw_create_task" {
  statement_id = "AllowAPIGAtewayInvokeCreateTask"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_task.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.tasks_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "get_task" {
  api_id                 = aws_apigatewayv2_api.tasks_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_task.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_task" {
  api_id    = aws_apigatewayv2_api.tasks_api.id
  route_key = "GET /tasks/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.get_task.id}"
}

resource "aws_lambda_permission" "api_gw_get_task" {
  statement_id  = "AllowAPIGatewayInvokeGetTask"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_task.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.tasks_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "list_tasks" {
  api_id                 = aws_apigatewayv2_api.tasks_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.list_tasks.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "list_tasks" {
  api_id    = aws_apigatewayv2_api.tasks_api.id
  route_key = "GET /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.list_tasks.id}"
}

resource "aws_lambda_permission" "api_gw_list_tasks" {
  statement_id  = "AllowAPIGatewayInvokeListTasks"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_tasks.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.tasks_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "delete_task" {
  api_id                 = aws_apigatewayv2_api.tasks_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.delete_task.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "delete_task" {
  api_id    = aws_apigatewayv2_api.tasks_api.id
  route_key = "DELETE /tasks/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_task.id}"
}

resource "aws_lambda_permission" "api_gw_delete_task" {
  statement_id  = "AllowAPIGatewayInvokeDeleteTask"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_task.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.tasks_api.execution_arn}/*/*"
}