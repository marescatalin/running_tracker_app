provider "aws" {
  region = "eu-west-2"
}

data "local_file" "lambda_source" {
  filename = "${path.cwd}/lambda.zip"
}

resource "aws_lambda_function" "lambda1" {
  function_name = "lambda1"
  role          = aws_iam_role.lambda.arn
  memory_size   = 128

  filename         = data.local_file.lambda_source.filename
  source_code_hash = data.local_file.lambda_source.content_sha256

  runtime       = "provided.al2023"
  handler       = "bootstrap"
  architectures = ["arm64"]

  environment {
    variables = {
      CLIENT_SECRET = "CLIENT_SECRET",
      REFRESH_TOKEN = "REFRESH_TOKEN"
    }
  }
}

