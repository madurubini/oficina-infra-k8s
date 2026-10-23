# Recursos "crus" do provider em vez do módulo terraform-aws-modules/eks: o
# módulo cria roles do IAM, e o Learner Lab não deixa. Cluster e nós usam a
# LabRole, que já vem com as permissões de EKS, EC2 e ECR.

data "aws_iam_role" "lab" {
  name = var.lab_role_nome
}

resource "aws_eks_cluster" "principal" {
  name     = var.cluster_nome
  version  = var.versao_kubernetes
  role_arn = data.aws_iam_role.lab.arn

  vpc_config {
    subnet_ids              = aws_subnet.publica[*].id
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  # Quem roda o apply (o principal da sessão do lab, o mesmo no pipeline e no
  # terminal) vira administrador do cluster e consegue usar o kubectl.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
}

resource "aws_eks_node_group" "principal" {
  cluster_name    = aws_eks_cluster.principal.name
  node_group_name = "${var.nome_projeto}-nos"
  node_role_arn   = data.aws_iam_role.lab.arn
  subnet_ids      = aws_subnet.publica[*].id
  instance_types  = [var.tipo_instancia]
  capacity_type   = "ON_DEMAND"

  scaling_config {
    min_size     = var.nos_minimo
    desired_size = var.nos_desejado
    max_size     = var.nos_maximo
  }

  update_config {
    max_unavailable = 1
  }

  # Sem a rota para a internet os nós não alcançam o control plane e o node
  # group fica preso em CREATE_FAILED.
  depends_on = [aws_route_table_association.publica]
}

# O HPA do oficina-app decide quantas réplicas subir olhando CPU e memória dos
# pods, e quem mede isso é o metrics-server. O EKS não o instala sozinho; como
# add-on, ele nasce e morre junto com o cluster. Depende dos nós porque roda
# como pod.
resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.principal.name
  addon_name   = "metrics-server"

  depends_on = [aws_eks_node_group.principal]
}
