data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "WebVisitorCounterRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
}

resource "aws_iam_policy" "lambda_permission_policy" {
  name = "WebVisitorCounterPolicy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      },
      {
        Action : [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ],
        Effect : "Allow",
        Resource : "${aws_dynamodb_table.ddb_table.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_permission_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.id
  policy_arn = aws_iam_policy.lambda_permission_policy.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../lambda/lambda_function.py"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "lambda_function" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "WebVisitorCounter"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.12"

  timeout     = 15
  memory_size = 1024
}