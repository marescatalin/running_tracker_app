data "aws_iam_policy_document" "assume_lambda_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dynamodb_write_policy_document" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:BatchWriteItem"
    ]
    effect    = "Allow"
    resources = [aws_dynamodb_table.basic-dynamodb-table.arn]
  }
}

data "aws_iam_policy_document" "dynamodb_read_policy_document" {
  statement {
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem"
    ]
    effect    = "Allow"
    resources = [aws_dynamodb_table.basic-dynamodb-table.arn]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "AssumeLambdaRole"
  description        = "Role for lambda to assume lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda_role.json
}

resource "aws_iam_policy" "dynamodb_write_policy" {
  name        = "dynamodb_write_policy"
  description = "Policy to allow Lambda to write to DynamoDB"

  policy = data.aws_iam_policy_document.dynamodb_write_policy_document.json
}

resource "aws_iam_policy" "dynamodb_read_policy" {
  name        = "dynamodb_read_policy"
  description = "Policy to allow Spring to read to DynamoDB"

  policy = data.aws_iam_policy_document.dynamodb_read_policy_document.json
}

resource "aws_iam_role_policy_attachment" "attach_policy_lambda" {
  policy_arn = aws_iam_policy.dynamodb_write_policy.arn
  role       = aws_iam_role.lambda.name
}

data "aws_iam_policy_document" "scheduler_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "EventBridgeSchedulerRole"
  description        = "Role for event bridge to assume scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_role.json
}

data "aws_iam_policy_document" "eventbridge_invoke_policy" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    effect    = "Allow"
    resources = [aws_lambda_function.lambda1.arn]
  }
}

resource "aws_iam_policy" "eventbridge_invoke_lambda" {
  name        = "EventBridgeInvokeLambdaPolicy"
  description = "Policy to allow Eventbridge to invoke to Lambda"

  policy = data.aws_iam_policy_document.eventbridge_invoke_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_policy_invoke" {
  policy_arn = aws_iam_policy.eventbridge_invoke_lambda.arn
  role       = aws_iam_role.scheduler.name
}

data "aws_iam_policy_document" "assume_ecs_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "ecs_task_execution_role"
  description        = "Role for ecs task execution to assume"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_role_policy_document.json
}

resource "aws_iam_role" "ecs_task" {
  name               = "ecs_task_role"
  description        = "Role for ecs task to assume"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_role_policy_document.json
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "ecsTaskPolicy"
  description = "Policy for ECS Task Role"
  policy      = data.aws_iam_policy_document.dynamodb_read_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_attachment" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "ECSExecutionPolicy"
  description = "Policy to allow ECS tasks to pull images and write logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:*",
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}
