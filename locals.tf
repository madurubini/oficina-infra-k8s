locals {
  tags_comuns = {
    Projeto       = var.nome_projeto
    Repo          = "oficina-infra-k8s"
    GerenciadoPor = "terraform"
  }

  zonas = slice(data.aws_availability_zones.disponiveis.names, 0, var.quantidade_zonas)
}

data "aws_availability_zones" "disponiveis" {
  state = "available"
}
