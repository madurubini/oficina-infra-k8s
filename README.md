# oficina-infra-k8s

Terraform da rede e do cluster Kubernetes da Oficina: VPC, subnets públicas, cluster EKS, node group
e ECR (registro das imagens Docker da API).

## Tecnologias

- **Terraform** ≥ 1.10 com provider `hashicorp/aws` 6.x
- **AWS**: VPC, EKS, EC2 (node group gerenciado), ECR, S3 (state remoto com lock nativo)
- **GitHub Actions** para plan/apply/destroy
- Ambiente: **AWS Academy Learner Lab** (por isso a `LabRole` e nenhum role criado aqui)

## Arquitetura deste repositório

```
                         Internet
                            │
                   ┌────────┴────────┐
                   │ Internet Gateway │
                   └────────┬────────┘
 VPC oficina-vpc 10.0.0.0/16│   (sem NAT Gateway)
 ┌──────────────────────────┼──────────────────────────┐
 │  subnet pública AZ-a     │     subnet pública AZ-b   │
 │  10.0.0.0/24             │     10.0.1.0/24           │
 │  ┌──────────────┐        │     ┌──────────────┐      │
 │  │ nó EC2       │        │     │ nó EC2       │      │
 │  │ t3.medium    │        │     │ t3.medium    │      │
 │  └──────┬───────┘        │     └──────┬───────┘      │
 │         └──────── node group ─────────┘              │
 │                     │                                │
 │          EKS oficina-eks (control plane AWS)         │
 │          namespaces: homolog · prod                  │
 └──────────────────────────────────────────────────────┘
        ECR oficina-app ◄── pipeline do oficina-app publica a imagem
        S3  <bucket>/infra-k8s/terraform.tfstate ──► lido pelo oficina-infra-db
```

Decisões:
- **Sem NAT Gateway**: ele cobra por hora e consumiria boa parte do saldo do lab. Os nós ficam em
  subnets públicas com IP público e falam direto com o EKS e o ECR.
- **Um cluster para os dois ambientes**: `homolog` e `prod` são namespaces do mesmo cluster.
  Separa os ambientes sem dobrar o custo.
- **Recursos crus do provider** (sem `terraform-aws-modules/eks`): o módulo cria roles do IAM, o que
  o Learner Lab bloqueia. Cluster e nós usam a `LabRole`.

## Saídas (consumidas pelos outros repos)

| Output | Quem usa |
|---|---|
| `vpc_id`, `vpc_cidr`, `subnet_ids`, `cluster_security_group_id` | `oficina-infra-db` (via `terraform_remote_state`) |
| `cluster_nome` | `oficina-app` (deploy com `aws eks update-kubeconfig`) |
| `ecr_url` | `oficina-app` (push da imagem) |

## Pipeline (CI/CD)

| Evento | O que roda |
|---|---|
| Pull request para `homolog` ou `main` | `fmt -check`, `validate`, `plan` (check obrigatório `terraform-plan`) |
| Push em `homolog` | `apply` — deploy de homologação |
| Push em `main` | `apply` — deploy de produção |
| Manual (**Actions → Terraform → Run workflow**, digitar `destruir`) | `destroy` |

Homologação e produção aplicam o mesmo state (infra única): `homolog` aplica primeiro, e o merge em
`main` confirma a mesma infraestrutura.

Fluxo de trabalho: `feat/*` → PR → `homolog` (deploy homolog) → PR → `main` (deploy prod).

### Configuração do repositório (uma vez)

- **Secrets** (Settings → Secrets and variables → Actions → *Secrets*): `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` — mudam a cada sessão do Learner Lab.
- **Variável** (mesma tela → *Variables*): `TF_STATE_BUCKET` = nome do bucket S3 do state.
- **Ruleset** da `main`: PR obrigatório, bloqueio de force push e deleção, e status check
  `terraform-plan` obrigatório.

## Como rodar localmente

```bash
# 1. Learner Lab: Start Lab → AWS Details → AWS CLI → copiar para ~/.aws/credentials
aws sts get-caller-identity

# 2. Bucket do state (só na primeira vez)
aws s3 mb s3://oficina-tfstate-SEU-RM --region us-east-1

# 3. Subir
cp backend.hcl.example backend.hcl   # e coloque o nome do bucket
terraform init -backend-config=backend.hcl
terraform apply

# 4. Conferir
aws eks update-kubeconfig --region us-east-1 --name oficina-eks
kubectl get nodes                    # 2 nós Ready

# 5. Derrubar ao terminar (depois de derrubar ④, ③ e ②)
terraform destroy
```

O cluster leva ~10–15 min para subir e ~10 min para cair.

## Custo (referência us-east-1)

| Recurso | Aproximado |
|---|---|
| Control plane EKS | US$ 0,10/h |
| 2 × t3.medium | US$ 0,083/h |
| ECR e S3 | centavos |

≈ **US$ 0,19/h** só com este repo ligado. Sempre rode o `destroy` ao terminar a sessão.

## Onde este repositório se encaixa

A Fase 3 é dividida em 4 repositórios, que se conversam por nomes na AWS, pelo state do Terraform
no S3 e por secrets do GitHub (nenhum importa código de outro):

| # | Repositório | O que cria |
|---|---|---|
| ① | [`oficina-infra-k8s`](https://github.com/madurubini/oficina-infra-k8s) | VPC, subnets, cluster EKS, nós e ECR |
| ② | [`oficina-infra-db`](https://github.com/madurubini/oficina-infra-db) | RDS Postgres dentro da VPC do ① |
| ③ | [`oficina-app`](https://github.com/madurubini/oficina-app) | API NestJS no EKS + Load Balancer |
| ④ | [`oficina-lambda-auth`](https://github.com/madurubini/oficina-lambda-auth) | API Gateway, Lambda `auth-cpf` e Lambda Authorizer |

**Ordem para subir:** ① → ② → ③ → ④. **Ordem para derrubar:** ④ → ③ → ② → ①.

Branches: **`main` = produção** (só recebe PR), **`homolog` = homologação**.
