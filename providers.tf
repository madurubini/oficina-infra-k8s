provider "aws" {
  region = var.regiao

  default_tags {
    tags = local.tags_comuns
  }
}
