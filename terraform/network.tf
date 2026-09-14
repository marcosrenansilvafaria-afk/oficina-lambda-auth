# Security Group da Lambda: por padrao AWS cria uma regra de egress "allow
# all" ao criar o SG - removemos explicitamente e liberamos apenas a porta
# 5432 em direcao ao Security Group do RDS (Repositorio 1), via referencia de
# ID (nao CIDR) para maior precisao.
resource "aws_security_group" "lambda" {
  name        = "oficina-${var.environment}-lambda-auth-sg"
  description = "Security Group da Lambda de autenticacao (egress restrito ao RDS)"
  vpc_id      = data.terraform_remote_state.db.outputs.vpc_id

  egress = []

  tags = {
    Name = "oficina-${var.environment}-lambda-auth-sg"
  }
}

resource "aws_security_group_rule" "lambda_egress_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda.id
  source_security_group_id = data.terraform_remote_state.db.outputs.rds_security_group_id
  description              = "Acesso PostgreSQL da Lambda ate o RDS"
}

# Regra reciproca no Security Group do RDS (criado no Repositorio 1),
# liberando a porta 5432 a partir do Security Group da Lambda. Mais preciso
# que a regra placeholder baseada em CIDR (auth_lambda_cidr_blocks) que ainda
# existe no Repositorio 1 - aquela pode ser removida em um commit futuro la,
# ja que esta regra por Security Group a torna redundante.
resource "aws_security_group_rule" "rds_ingress_from_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.db.outputs.rds_security_group_id
  source_security_group_id = aws_security_group.lambda.id
  description              = "Acesso PostgreSQL a partir da Lambda de autenticacao (Repositorio 2)"
}
