# Os outputs ficam no state do S3; o repo oficina-infra-db os lê com
# terraform_remote_state para criar o RDS dentro desta mesma VPC.

output "regiao" {
  description = "Região onde a infraestrutura foi criada."
  value       = var.regiao
}

output "vpc_id" {
  description = "Id da VPC."
  value       = aws_vpc.principal.id
}

output "vpc_cidr" {
  description = "Faixa de IPs da VPC."
  value       = aws_vpc.principal.cidr_block
}

output "subnet_ids" {
  description = "Ids das subnets públicas."
  value       = aws_subnet.publica[*].id
}

output "cluster_nome" {
  description = "Nome do cluster EKS."
  value       = aws_eks_cluster.principal.name
}

output "cluster_endpoint" {
  description = "Endereço da API do Kubernetes."
  value       = aws_eks_cluster.principal.endpoint
}

output "cluster_security_group_id" {
  description = "Security group que o EKS associa ao control plane e aos nós; o RDS libera a porta 5432 para ele."
  value       = aws_eks_cluster.principal.vpc_config[0].cluster_security_group_id
}

output "ecr_url" {
  description = "URL do repositório do ECR (sem a tag)."
  value       = aws_ecr_repository.aplicacao.repository_url
}

output "proximo_passo" {
  description = "Comando para apontar o kubectl para o cluster."
  value       = "aws eks update-kubeconfig --region ${var.regiao} --name ${aws_eks_cluster.principal.name}"
}
