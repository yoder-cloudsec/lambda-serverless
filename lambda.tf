data "archive_file" "create_task_zip" {
  type = "zip"
  source_file = "${path.module}/functions/create_task.py"
  output_path = "${path.module}/functions/create_task.zip"
}

data "archive_file" "get_task_zip" {
  type        = "zip"
  source_file = "${path.module}/functions/get_task.py"
  output_path = "${path.module}/functions/get_task.zip"
}

data "archive_file" "list_tasks_zip" {
  type        = "zip"
  source_file = "${path.module}/functions/list_tasks.py"
  output_path = "${path.module}/functions/list_tasks.zip"
}

data "archive_file" "delete_task_zip" {
  type        = "zip"
  source_file = "${path.module}/functions/delete_task.py"
  output_path = "${path.module}/functions/delete_task.zip"
}

resource "aws_lambda_function" "get_task" {
  function_name    = "get-task"
  filename         = data.archive_file.get_task_zip.output_path
  source_code_hash = data.archive_file.get_task_zip.output_base64sha256
  handler          = "get_task.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec.arn

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.tasks.name }
  }
}

resource "aws_lambda_function" "list_tasks" {
  function_name    = "list-tasks"
  filename         = data.archive_file.list_tasks_zip.output_path
  source_code_hash = data.archive_file.list_tasks_zip.output_base64sha256
  handler          = "list_tasks.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec.arn

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.tasks.name }
  }
}

resource "aws_lambda_function" "delete_task" {
  function_name    = "delete-task"
  filename         = data.archive_file.delete_task_zip.output_path
  source_code_hash = data.archive_file.delete_task_zip.output_base64sha256
  handler          = "delete_task.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec.arn

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.tasks.name }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "task-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "lambda.amazonaws.com"
            }
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda-dynamodb-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.tasks.arn
      }
    ]
  })
}

resource "aws_lambda_function" "create_task" {
  function_name = "create-task"
  filename = data.archive_file.create_task_zip.output_path
  source_code_hash = data.archive_file.create_task_zip.output_base64sha256
  handler = "create_task.handler"
  runtime = "python3.12"
  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.tasks.name
    }
  }
}