terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # O nome do bucket muda de aluno para aluno, então ele chega no init:
  #   terraform init -backend-config=backend.hcl
  # A key é fixa porque o repo oficina-infra-db lê este state por ela.
  backend "s3" {
    key          = "infra-k8s/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
