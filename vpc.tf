# Só subnets públicas e nenhum NAT Gateway: o NAT custa por hora e sozinho
# consumiria boa parte do saldo do Learner Lab. Os nós ganham IP público e
# falam com o control plane do EKS e com o ECR direto pelo Internet Gateway.

resource "aws_vpc" "principal" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.nome_projeto}-vpc"
  }
}

resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${var.nome_projeto}-igw"
  }
}

resource "aws_subnet" "publica" {
  count = length(local.zonas)

  vpc_id                  = aws_vpc.principal.id
  availability_zone       = local.zonas[count.index]
  cidr_block              = cidrsubnet(var.cidr_vpc, 8, count.index)
  map_public_ip_on_launch = true

  # As tags kubernetes.io/* dizem ao EKS em quais subnets ele pode criar o
  # Load Balancer do Service do tipo LoadBalancer.
  tags = {
    Name                                        = "${var.nome_projeto}-publica-${local.zonas[count.index]}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_nome}" = "shared"
  }
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.principal.id
  }

  tags = {
    Name = "${var.nome_projeto}-rotas-publicas"
  }
}

resource "aws_route_table_association" "publica" {
  count = length(aws_subnet.publica)

  subnet_id      = aws_subnet.publica[count.index].id
  route_table_id = aws_route_table.publica.id
}
