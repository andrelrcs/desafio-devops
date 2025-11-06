# 🚀 CSV Processor - Infraestrutura AWS Serverless

Solução completa para processamento de arquivos CSV na AWS usando Lambda, S3 e infraestrutura como código (Terraform).

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Instalação e Deploy](#instalação-e-deploy)
- [Uso](#uso)
- [Monitoramento](#monitoramento)
- [CI/CD](#cicd)
- [Segurança](#segurança)
- [Custos](#custos)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

Este projeto moderniza uma aplicação Python legada que processa arquivos CSV da tabela FIPE, calculando preços médios de veículos agrupados por ano e marca.

### Funcionalidades

- ✅ Processamento automático de CSV via S3 events
- ✅ Arquitetura serverless (AWS Lambda)
- ✅ Infraestrutura como código (Terraform)
- ✅ CI/CD com GitHub Actions
- ✅ Monitoramento com CloudWatch
- ✅ Segurança (IAM least privilege, encryption)
- ✅ Containerização com Docker

---

## 🏗️ Arquitetura

```
┌─────────────┐      S3 Event      ┌──────────────┐      Write JSON      ┌─────────────┐
│  S3 Input   │ ──────────────────> │ Lambda (ECR) │ ──────────────────>  │ S3 Output   │
│   Bucket    │                     │  Container   │                      │   Bucket    │
└─────────────┘                     └──────────────┘                      └─────────────┘
                                            │
                                            │ Logs
                                            ▼
                                    ┌──────────────┐
                                    │  CloudWatch  │
                                    │  Logs/Alarms │
                                    └──────────────┘
```

### Componentes

| Componente | Descrição | Justificativa |
|------------|-----------|---------------|
| **AWS Lambda** | Executa processamento | Event-driven, custo-benefício para workload intermitente |
| **S3** | Armazenamento de arquivos | Durável, escalável, trigger nativo |
| **ECR** | Registry de containers | Imagens Docker versionadas |
| **CloudWatch** | Logs e métricas | Observabilidade integrada |
| **IAM** | Controle de acesso | Least privilege, segurança |

Para detalhes da decisão arquitetural, veja [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 📦 Pré-requisitos

### Software Necessário

- **AWS CLI** (v2.x): [Instalação](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform** (>= 1.6.0): [Instalação](https://developer.hashicorp.com/terraform/downloads)
- **Docker** (>= 20.x): [Instalação](https://docs.docker.com/get-docker/)
- **Git**: [Instalação](https://git-scm.com/downloads)

### Conta AWS

- Conta AWS ativa
- Credenciais configuradas com permissões para:
  - S3, Lambda, ECR, IAM, CloudWatch, EC2 (VPC - se necessário)

### Configuração AWS CLI

```bash
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: us-east-1
# Default output format: json
```

---

## 🚀 Instalação e Deploy

### Opção 1: Deploy Manual (Primeiro Deploy)

#### 1. Clone o Repositório

```bash
git clone https://github.com/your-username/desafio-devops.git
cd desafio-devops
```

#### 2. Crie o Repositório ECR Manualmente (Primeira Vez)

```bash
# Defina variáveis
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ENVIRONMENT=dev
export REPOSITORY_NAME=csv-processor-${ENVIRONMENT}

# Crie o repositório ECR
aws ecr create-repository \
  --repository-name ${REPOSITORY_NAME} \
  --region ${AWS_REGION} \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256
```

#### 3. Build e Push da Imagem Docker

```bash
# Login no ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build da imagem
docker build -t ${REPOSITORY_NAME}:latest .

# Tag da imagem
docker tag ${REPOSITORY_NAME}:latest \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest

# Push da imagem
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest
```

#### 4. Deploy da Infraestrutura com Terraform

```bash
# Inicialize o Terraform
terraform init

# Valide a configuração
terraform validate

# Visualize o plano de execução
terraform plan \
  -var="environment=${ENVIRONMENT}" \
  -var="aws_region=${AWS_REGION}" \
  -var="lambda_image_uri=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest"

# Aplique a infraestrutura
terraform apply \
  -var="environment=${ENVIRONMENT}" \
  -var="aws_region=${AWS_REGION}" \
  -var="lambda_image_uri=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest" \
  -auto-approve
```

#### 5. Capture os Outputs

```bash
# Salve os outputs importantes
terraform output > terraform_outputs.txt

# Ou acesse outputs específicos
export INPUT_BUCKET=$(terraform output -raw input_bucket_name)
export OUTPUT_BUCKET=$(terraform output -raw output_bucket_name)
export LAMBDA_FUNCTION=$(terraform output -raw lambda_function_name)

echo "Input Bucket: $INPUT_BUCKET"
echo "Output Bucket: $OUTPUT_BUCKET"
echo "Lambda Function: $LAMBDA_FUNCTION"
```

### Opção 2: Deploy Automatizado (CI/CD)

Para deploys subsequentes, use o pipeline GitHub Actions (veja seção [CI/CD](#cicd)).

---

## 💻 Uso

### Processar um Arquivo CSV

#### 1. Upload Manual via AWS CLI

```bash
# Upload do arquivo CSV
aws s3 cp tabela-fipe-historico-precos.csv s3://${INPUT_BUCKET}/

# Aguarde o processamento (automático via S3 event)
sleep 10

# Verifique o arquivo de saída
aws s3 ls s3://${OUTPUT_BUCKET}/

# Download do resultado
aws s3 cp s3://${OUTPUT_BUCKET}/tabela-fipe-historico-precos_preco_medio.json .
```

#### 2. Upload via Console AWS

1. Acesse o [S3 Console](https://console.aws.amazon.com/s3/)
2. Navegue até o bucket de input (ex: `csv-processor-dev-input-xxxxx`)
3. Clique em **Upload** → Selecione seu arquivo CSV
4. Aguarde o processamento
5. Verifique o bucket de output

#### 3. Upload Programático (Python)

```python
import boto3

s3 = boto3.client('s3')

# Upload
s3.upload_file(
    'local-file.csv',
    'csv-processor-dev-input-xxxxx',
    'local-file.csv'
)

# Download do resultado após processamento
s3.download_file(
    'csv-processor-dev-output-xxxxx',
    'local-file_preco_medio.json',
    'output.json'
)
```

### Formato do Arquivo CSV de Entrada

O CSV deve conter as seguintes colunas:

```csv
codigoFipe,marca,modelo,anoModelo,mesReferencia,anoReferencia,valor
001016-1,Acura,Integra GS 1.8,1992,janeiro,1992,12104.23
002100-5,Audi,80 2.0,1995,fevereiro,1995,14567.89
```

### Formato do JSON de Saída

```json
{
  "1992": {
    "Acura": 12104.23,
    "Audi": 14567.89
  },
  "1995": {
    "Acura": 49296.0
  }
}
```

---

## 📊 Monitoramento

### CloudWatch Logs

```bash
# Visualizar logs em tempo real
aws logs tail /aws/lambda/${LAMBDA_FUNCTION} --follow

# Últimas 50 linhas
aws logs tail /aws/lambda/${LAMBDA_FUNCTION} --since 1h

# Filtrar por erro
aws logs filter-log-events \
  --log-group-name /aws/lambda/${LAMBDA_FUNCTION} \
  --filter-pattern "ERROR"
```

### CloudWatch Metrics

Acesse o [CloudWatch Console](https://console.aws.amazon.com/cloudwatch/) para visualizar:

- **Invocações**: Número de execuções
- **Duração**: Tempo médio de processamento
- **Erros**: Taxa de falhas
- **Throttles**: Limitações de concorrência

### CloudWatch Alarms

Alarmes configurados automaticamente:

| Alarme | Condição | Ação |
|--------|----------|------|
| High Error Rate | Taxa de erro > 5% | Email notification |
| High Duration | Duração > 3 minutos | Email notification |
| Throttles | Throttling detectado | Email notification |

Para configurar email de notificações:

```bash
terraform apply -var="alarm_email=seu-email@example.com"
```

### Dashboard

Acesse o dashboard no CloudWatch:

```bash
# URL do dashboard
echo "https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=csv-processor-${ENVIRONMENT}-lambda-dashboard"
```

---

## 🔄 CI/CD

### GitHub Actions Pipeline

O pipeline automatiza:

1. **Validate**: Lint do código, validação Terraform
2. **Build**: Build e push da imagem Docker para ECR
3. **Deploy**: Deploy da infraestrutura e atualização da Lambda
4. **Test**: Testes de integração

### Configuração

#### 1. Adicione Secrets no GitHub

Vá em: `Settings → Secrets and variables → Actions → New repository secret`

Adicione:

- `AWS_ACCESS_KEY_ID`: Sua AWS Access Key
- `AWS_SECRET_ACCESS_KEY`: Sua AWS Secret Key

#### 2. Triggers

O pipeline executa:

- **Push para `main`**: Deploy em produção
- **Push para `develop`**: Deploy em desenvolvimento
- **Pull Request**: Validação e testes
- **Manual**: Dispatch manual com seleção de ambiente

#### 3. Executar Manualmente

```bash
# Via GitHub UI
Actions → Deploy to AWS → Run workflow → Selecione environment

# Via GitHub CLI
gh workflow run deploy.yml -f environment=dev
```

### Ambientes

| Branch | Ambiente | Deploy Automático |
|--------|----------|-------------------|
| `main` | prod | ✅ Sim |
| `develop` | dev | ✅ Sim |
| `feature/*` | - | ❌ Apenas validação |

---

## 🔒 Segurança

### Princípios Implementados

#### 1. Least Privilege (IAM)

Lambda tem apenas as permissões necessárias:

```
✅ s3:GetObject no input bucket
✅ s3:PutObject no output bucket
✅ logs:CreateLogStream, logs:PutLogEvents
❌ Sem s3:DeleteObject
❌ Sem acesso a outros serviços
```

#### 2. Encryption

- **S3**: Server-Side Encryption (SSE-S3)
- **ECR**: Encryption at rest (AES256)
- **CloudWatch Logs**: Encryption in transit

#### 3. Network Security

- **S3 Buckets**: Block all public access
- **Lambda**: Sem acesso público (trigger apenas via S3)

#### 4. Secrets Management

Nunca commite credenciais! Use:

- **AWS Secrets Manager** para secrets (API keys, DB passwords)
- **Environment variables** para configurações não-sensíveis

```bash
# Adicionar secret
aws secretsmanager create-secret \
  --name csv-processor/${ENVIRONMENT}/api-key \
  --secret-string "your-secret-value"

# Atualizar Lambda para usar o secret
# (adicione permissão secretsmanager:GetSecretValue no IAM)
```

### Security Best Practices

- ✅ Use MFA na conta AWS
- ✅ Rotacione access keys regularmente
- ✅ Habilite AWS CloudTrail para auditoria
- ✅ Use AWS Config para compliance
- ✅ Escanear imagens Docker (Trivy no CI/CD)

---

## 💰 Custos

### Estimativa Mensal

Para **1000 processamentos/mês** (CSV ~10MB, tempo de execução ~30s):

| Serviço | Uso | Custo |
|---------|-----|-------|
| Lambda | 1000 invocações × 30s × 512MB | $0.50 |
| S3 Storage | 1GB input + 1GB output | $0.05 |
| S3 Requests | 2000 requests | $0.01 |
| ECR | 500MB imagem | $0.05 |
| CloudWatch | Logs + Metrics | $0.50 |
| Data Transfer | Minimal | $0.05 |
| **Total** | | **~$1.20/mês** |

### Free Tier

AWS oferece:

- **Lambda**: 1M requests/mês + 400.000 GB-seconds/mês
- **S3**: 5GB storage + 20.000 GET requests
- **ECR**: 500MB storage/mês (12 meses)

**Conclusão**: Para baixo volume, o custo pode ser **$0** (free tier).

### Otimização de Custos

1. **Lambda Memory**: Ajuste para o mínimo necessário
2. **S3 Lifecycle**: Mova dados antigos para Glacier
3. **CloudWatch Logs**: Reduza retenção para 3-7 dias
4. **ECR Lifecycle**: Mantenha apenas últimas 5 imagens

```bash
# Ajustar memória da Lambda
terraform apply -var="lambda_memory_size=256"

# Ajustar retenção de logs
terraform apply -var="log_retention_days=3"
```

---

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. Lambda não é invocada após upload do CSV

**Sintomas**: Arquivo enviado, mas nenhum processamento ocorre.

**Soluções**:

```bash
# Verifique se o trigger S3 está configurado
aws lambda list-event-source-mappings \
  --function-name ${LAMBDA_FUNCTION}

# Verifique logs
aws logs tail /aws/lambda/${LAMBDA_FUNCTION} --since 5m

# Teste manualmente
aws lambda invoke \
  --function-name ${LAMBDA_FUNCTION} \
  --payload '{"Records":[{"s3":{"bucket":{"name":"'${INPUT_BUCKET}'"},"object":{"key":"test.csv"}}}]}' \
  response.json
```

#### 2. Erro "Access Denied" ao escrever no S3

**Causa**: Permissões IAM insuficientes.

**Solução**:

```bash
# Verifique a policy IAM
aws iam get-role-policy \
  --role-name csv-processor-dev-lambda-role \
  --policy-name csv-processor-dev-lambda-s3-policy

# Reaplique o Terraform
terraform apply
```

#### 3. Lambda timeout

**Causa**: Arquivo muito grande ou processamento lento.

**Solução**:

```bash
# Aumente timeout e memória
terraform apply \
  -var="lambda_timeout=600" \
  -var="lambda_memory_size=1024"
```

#### 4. Imagem Docker não encontrada

**Causa**: Imagem não foi enviada para ECR ou URI incorreta.

**Solução**:

```bash
# Liste imagens no ECR
aws ecr list-images --repository-name ${REPOSITORY_NAME}

# Reconstrua e envie
docker build -t ${REPOSITORY_NAME}:latest .
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest

# Atualize Lambda
aws lambda update-function-code \
  --function-name ${LAMBDA_FUNCTION} \
  --image-uri ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest
```

#### 5. Terraform state locked

**Causa**: Outro terraform apply está rodando ou foi interrompido.

**Solução**:

```bash
# Force unlock (use com cuidado!)
terraform force-unlock <LOCK_ID>

# Ou delete o lock manualmente no S3/DynamoDB backend
```

### Logs de Debug

```bash
# Habilite debug logging
terraform apply -var="lambda_log_level=DEBUG"

# Visualize logs detalhados
aws logs tail /aws/lambda/${LAMBDA_FUNCTION} --follow --format detailed
```

---

## 🧪 Testes

### Teste Local (Docker)

```bash
# Build local
docker build -t csv-processor:test .

# Execute localmente
docker run -p 9000:8080 csv-processor:test

# Em outro terminal, invoque
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{"Records":[{"s3":{"bucket":{"name":"test"},"object":{"key":"test.csv"}}}]}'
```

### Teste na AWS

```bash
# Upload de arquivo teste
echo "codigoFipe,marca,modelo,anoModelo,mesReferencia,anoReferencia,valor" > test.csv
echo "001,TestBrand,TestModel,2020,01,2020,50000.00" >> test.csv

aws s3 cp test.csv s3://${INPUT_BUCKET}/test.csv

# Aguarde processamento
sleep 10

# Verifique resultado
aws s3 cp s3://${OUTPUT_BUCKET}/test_preco_medio.json - | jq .

# Cleanup
aws s3 rm s3://${INPUT_BUCKET}/test.csv
aws s3 rm s3://${OUTPUT_BUCKET}/test_preco_medio.json
```

---

## 🗑️ Destruição da Infraestrutura

**⚠️ ATENÇÃO**: Esta ação é **irreversível** e deletará todos os recursos.

```bash
# Visualize o que será destruído
terraform plan -destroy

# Destrua a infraestrutura
terraform destroy -auto-approve

# Limpe buckets S3 manualmente (se necessário)
aws s3 rb s3://${INPUT_BUCKET} --force
aws s3 rb s3://${OUTPUT_BUCKET} --force

# Delete repositório ECR
aws ecr delete-repository \
  --repository-name ${REPOSITORY_NAME} \
  --force
```

---

## 📚 Documentação Adicional

- [Decisões Arquiteturais](ARCHITECTURE.md)
- [Documentação da Aplicação Original](https://github.com/rafaelmedeirosenacom/desafio-devops)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🤝 Contribuindo

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit: `git commit -am 'Add nova funcionalidade'`
4. Push: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

---

## 📝 Licença

Este projeto é open source e está sob a licença MIT.

---

## 👥 Autores

- **Seu Nome** - DevOps Engineer
- Baseado no desafio de [rafaelmedeirosenacom](https://github.com/rafaelmedeirosenacom/desafio-devops)

---

## 🎯 Status do Projeto

✅ Infraestrutura provisionada via Terraform  
✅ Aplicação containerizada  
✅ CI/CD implementado  
✅ Monitoramento configurado  
✅ Segurança implementada (least privilege)  
✅ Documentação completa  

---

**🚀 Deploy realizado com sucesso! Happy coding!**