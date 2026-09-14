# -----------------------------------------------------------------------------
# Geral
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "Região AWS onde os recursos serão provisionados. Deve ser a mesma do Repositório 1 (RDS)."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nome do ambiente (ex: production, development). Deve corresponder ao ambiente do Repositório 1 cujo state sera lido (mesmo valor de TF_ENVIRONMENT usado la)."
  type        = string
  default     = "development"
}

variable "db_state_bucket" {
  description = "Nome do bucket S3 onde o state do Repositório 1 (oficina-db-infrastructure) está armazenado."
  type        = string
}

# -----------------------------------------------------------------------------
# JWT
# -----------------------------------------------------------------------------

variable "jwt_secret" {
  description = "Segredo usado para assinar os tokens JWT emitidos por esta Lambda. NUNCA definir default nem preencher em .tfvars — fornecer via TF_VAR_jwt_secret."
  type        = string
  sensitive   = true
}

variable "jwt_expires_in" {
  description = "Tempo de expiração do token JWT (formato aceito pela lib jsonwebtoken, ex: '1h', '30m')."
  type        = string
  default     = "1h"
}

# -----------------------------------------------------------------------------
# Lambda
# -----------------------------------------------------------------------------

variable "lambda_memory_size" {
  description = "Memória alocada para a Lambda (MB). Afeta também a CPU proporcionalmente."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout máximo de execução da Lambda (segundos)."
  type        = number
  default     = 10
}

variable "lambda_reserved_concurrency" {
  description = "Limite de execuções concorrentes reservadas para a Lambda (protege contra custo inesperado em caso de abuso/loop de chamadas)."
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs no CloudWatch Logs (custo de armazenamento proporcional ao período)."
  type        = number
  default     = 7
}
