# Backend remoto (S3 + DynamoDB lock) - reaproveita o MESMO bucket e tabela de
# lock do Repositorio 1 (oficina-db-infrastructure), com uma "key" diferente
# para isolar o state deste repositorio. Bucket/tabela ja foram criados no
# bootstrap do Repo 1 - ver README daquele repositorio.
#
# Os valores reais de bucket/region/dynamodb_table sao passados no
# `terraform init` via `-backend-config`, para nao hardcodar nomes especificos
# de conta/ambiente neste arquivo versionado.
terraform {
  backend "s3" {
    key            = "oficina-lambda-auth/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "oficina-db-terraform-locks"
  }
}
