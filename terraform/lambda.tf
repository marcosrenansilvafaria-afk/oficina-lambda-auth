data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../dist/handler.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  #checkov:skip=CKV_AWS_338: Retencao de 1 ano aumentaria custo de armazenamento sem beneficio real para um projeto de estudo/demonstracao. 7 dias e suficiente para debug.
  #checkov:skip=CKV_AWS_158: Criptografia com CMK customizada tem custo mensal adicional (~US$1/mes por chave). O log group ja e criptografado com a chave gerenciada pela AWS por padrao.
  name              = "/aws/lambda/oficina-${var.environment}-lambda-auth"
  retention_in_days = var.log_retention_days
}

# Dead Letter Queue: eventos de falha na invocacao assincrona sao enviados
# aqui para investigacao. SQS Standard esta dentro do free tier (1M
# requisicoes/mes, gratuito por tempo indeterminado) - custo efetivo zero
# para o volume deste projeto.
resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "oficina-${var.environment}-lambda-auth-dlq"
  message_retention_seconds = 1209600 # 14 dias (maximo do SQS)

  tags = {
    Name = "oficina-${var.environment}-lambda-auth-dlq"
  }
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
  #checkov:skip=CKV_AWS_290: Acoes de ENI (ec2:CreateNetworkInterface etc) nao suportam Resource com ARN especifico - mesmo padrao da policy gerenciada AWSLambdaVPCAccessExecutionRole.
  #checkov:skip=CKV_AWS_355: Mesma justificativa acima - limitacao da API EC2 para acoes de ENI, nao falta de escopo intencional.
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
        # As acoes de ENI da EC2 nao suportam permissoes em nivel de recurso -
        # e o mesmo padrao usado pela policy gerenciada da AWS
        # "AWSLambdaVPCAccessExecutionRole". Resource "*" e inevitavel aqui.
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
      },
      {
        Sid      = "DeadLetterQueue"
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.lambda_dlq.arn
      }
    ]
  })
}

resource "aws_lambda_function" "auth" {
  #checkov:skip=CKV_AWS_272: Code signing (AWS Signer) exige criar um Signing Profile e um Code Signing Config extras, complexidade desproporcional para um projeto de estudo/demonstracao com deploy via CI confiavel (branch protection + OIDC).
  #checkov:skip=CKV_AWS_173: As variaveis de ambiente ja sao criptografadas em repouso pela chave gerenciada padrao da AWS (aws/lambda). Uma CMK customizada teria custo mensal adicional (~US$1/mes).
  function_name = "oficina-${var.environment}-lambda-auth"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

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
