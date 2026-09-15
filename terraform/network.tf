# Security Group da Lambda: a regra de egress para o RDS e declarada INLINE
# (nao como aws_security_group_rule separado) porque misturar um bloco
# inline "egress = []" com uma resource aws_security_group_rule separada faz
# o Terraform tratar o bloco inline como autoritativo e apagar a regra da
# resource separada a cada apply - a Lambda ficava sem nenhuma rota de saida
# real para o RDS (bug encontrado em producao: Lambda dando timeout ao
# tentar conectar no banco).
resource "aws_security_group" "lambda" {
  name        = "oficina-${var.environment}-lambda-auth-sg"
  description = "Security Group da Lambda de autenticacao (egress restrito ao RDS)"
  vpc_id      = data.terraform_remote_state.db.outputs.vpc_id

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.db.outputs.rds_security_group_id]
    description     = "Acesso PostgreSQL da Lambda ate o RDS"
  }

  tags = {
    Name = "oficina-${var.environment}-lambda-auth-sg"
  }
}

resource "aws_security_group_rule" "rds_ingress_from_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.db.outputs.rds_security_group_id
  source_security_group_id = aws_security_group.lambda.id
  description              = "Acesso PostgreSQL a partir da Lambda de autenticacao (Repositorio 2)"
}
