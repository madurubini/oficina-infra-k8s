variable "regiao" {
  description = "Região da AWS. O Learner Lab só libera us-east-1 e us-west-2."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.regiao)
    error_message = "O Learner Lab só permite us-east-1 ou us-west-2."
  }
}

variable "nome_projeto" {
  description = "Prefixo dos nomes e valor da tag Projeto em todos os recursos."
  type        = string
  default     = "oficina"
}

variable "cluster_nome" {
  description = "Nome do cluster EKS. O repo oficina-app faz o deploy procurando este nome."
  type        = string
  default     = "oficina-eks"
}

variable "versao_kubernetes" {
  description = "Versão do Kubernetes do cluster EKS."
  type        = string
  default     = "1.33"
}

variable "cidr_vpc" {
  description = "Faixa de IPs da VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.cidr_vpc))
    error_message = "Use um CIDR válido, por exemplo 10.0.0.0/16."
  }
}

variable "quantidade_zonas" {
  description = "Em quantas zonas de disponibilidade espalhar as subnets. O EKS exige pelo menos 2."
  type        = number
  default     = 2

  validation {
    condition     = var.quantidade_zonas >= 2 && var.quantidade_zonas <= 3
    error_message = "O EKS exige pelo menos 2 zonas; acima de 3 só aumenta o custo."
  }
}

variable "tipo_instancia" {
  description = "Tipo das instâncias EC2 dos nós. O Learner Lab bloqueia tipos grandes."
  type        = string
  default     = "t3.medium"
}

variable "nos_minimo" {
  description = "Número mínimo de nós do node group."
  type        = number
  default     = 2
}

variable "nos_desejado" {
  description = "Número de nós com que o node group sobe."
  type        = number
  default     = 2
}

variable "nos_maximo" {
  description = "Número máximo de nós do node group."
  type        = number
  default     = 3

  validation {
    condition     = var.nos_maximo <= 5
    error_message = "O Learner Lab limita a quantidade de instâncias; mantenha no máximo 5 nós."
  }
}

variable "lab_role_nome" {
  description = "Role do IAM pronta do Learner Lab, usada pelo cluster e pelos nós (o lab não deixa criar roles)."
  type        = string
  default     = "LabRole"
}

variable "ecr_repositorio" {
  description = "Nome do repositório do ECR onde o pipeline do oficina-app publica a imagem."
  type        = string
  default     = "oficina-app"
}
