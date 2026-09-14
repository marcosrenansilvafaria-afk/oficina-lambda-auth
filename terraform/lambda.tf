data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../dist/handler.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/oficina-${var.environment}-lambda-auth"
  retention_in_days = var.log_retention_days
}

resource "aws_iam_role" "lambda_exec" {
  name = "oficina-${var.environment}-lambda-auth-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Permissoes minimas: logs (execucao basica) + gerenciamento de ENI para a
# Lambda poder se juntar a VPC privada do RDS. NAO inclui permissao de
# leitura no Secrets Manager/SSM: os valores sao injetados como variaveis de
# ambiente no deploy (ver secrets.tf), entao a funcao nao precisa chamar
# essas APIs em runtime.
resource "aws_iam_role_policy" "lambda_exec" {
  name = "oficina-${var.environment}-lambda-auth-exec-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Logs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      },
      {
        Sid    = "VpcNetworkInterfaces"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "auth" {
  function_name = "oficina-${var.environment}-lambda-auth"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  vpc_config {
    subnet_ids         = data.terraform_remote_state.db.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST        = data.terraform_remote_state.db.outputs.db_instance_address
      DB_PORT        = tostring(data.terraform_remote_state.db.outputs.db_instance_port)
      DB_NAME        = data.terraform_remote_state.db.outputs.db_name
      DB_USER        = data.terraform_remote_state.db.outputs.db_username
      DB_PASSWORD    = data.terraform_remote_state.db.outputs.db_master_password
      JWT_SECRET     = var.jwt_secret
      JWT_EXPIRES_IN = var.jwt_expires_in
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy.lambda_exec]

  tags = {
    Name = "oficina-${var.environment}-lambda-auth"
  }
}
