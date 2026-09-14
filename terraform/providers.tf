provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "oficina"
      Component   = "lambda-auth"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
