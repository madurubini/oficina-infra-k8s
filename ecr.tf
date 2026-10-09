resource "aws_ecr_repository" "aplicacao" {
  name                 = var.ecr_repositorio
  image_tag_mutability = "MUTABLE"

  # Permite o destroy mesmo com imagens dentro, para a rotina subir/derrubar.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Cada push do pipeline gera uma imagem; guardar só as últimas evita pagar
# armazenamento por imagens que ninguém vai usar.
resource "aws_ecr_lifecycle_policy" "aplicacao" {
  repository = aws_ecr_repository.aplicacao.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Mantém só as 10 imagens mais recentes"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
