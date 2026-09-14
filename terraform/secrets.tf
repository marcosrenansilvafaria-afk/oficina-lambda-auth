# Espelha as credenciais de conexao do RDS (lidas do state do Repositorio 1
# via remote state) em um segredo proprio no AWS Secrets Manager. Existe para
# fins de auditabilidade/rotacao e para aderir ao padrao pedido no enunciado
# da Sprint 2 ("busca o segredo no AWS Secrets Manager").
#
# IMPORTANTE: a Lambda em si NAO chama a API do Secrets Manager em runtime -
# os valores sao lidos por este Terraform (rodando fora da VPC, no GitHub
# Actions/local) e injetados diretamente como variaveis de ambiente da
# funcao (ver lambda.tf). Isso evita a necessidade de VPC Interface Endpoint
# ou NAT Gateway para a Lambda alcancar a API do Secrets Manager de dentro da
# VPC privada, o que teria custo mensal real nao coberto pelo free tier.
# A troca: rotacionar a senha exige um novo `terraform apply`.
resource "aws_secretsmanager_secret" "db_credentials" {
  #checkov:skip=CKV2_AWS_57: Rotacao automatica exigiria uma Lambda de rotacao dedicada - complexidade desproporcional para um segredo que e apenas um espelho, atualizado a cada terraform apply.
  #checkov:skip=CKV_AWS_149: Chave gerenciada pela AWS (aws/secretsmanager) ja criptografa o segredo por padrao; CMK customizada tem custo mensal adicional (~US$1/mes).
  name        = "oficina/${var.environment}/lambda-auth/db-credentials"
  description = "Credenciais de conexao com o RDS PostgreSQL, espelhadas do Repositorio 1 para uso pelo Repositorio 2 (Lambda de autenticacao)"

  tags = {
    Name = "oficina-${var.environment}-lambda-auth-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = data.terraform_remote_state.db.outputs.db_username
    password = data.terraform_remote_state.db.outputs.db_master_password
    host     = data.terraform_remote_state.db.outputs.db_instance_address
    port     = data.terraform_remote_state.db.outputs.db_instance_port
  })
}
