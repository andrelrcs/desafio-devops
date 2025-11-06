# Decisões Arquiteturais

## Escolha da Arquitetura: AWS Lambda + S3

### Por que AWS Lambda?
- **Custo-benefício**: Pay-per-use, ideal para processamento intermitente
- **Simplicidade**: Sem necessidade de gerenciar servidores
- **Escalabilidade**: Automática baseada na demanda
- **Adequado ao caso**: Processamento de arquivo CSV é rápido e sem estado

### Arquitetura

```
Input Bucket → Lambda Function → Output Bucket
     └─────────→ CloudWatch Logs ←─────────┘
```

### Componentes Principais

#### 1. S3 Buckets
- **Input**: Recebe arquivos CSV
- **Output**: Armazena JSONs processados
- **Segurança**: Criptografia ativada, acesso privado

#### 2. Lambda Function
- **Runtime**: Python 3.10
- **Memória**: 128 MB
- **Timeout**: 30 segundos
- **Trigger**: Eventos do S3 (upload de CSV)

#### 3. IAM (Segurança)
- Permissões mínimas necessárias:
  - Ler do bucket de input
  - Escrever no bucket de output
  - Criar logs no CloudWatch

### Custos Estimados
Para 1000 processamentos/mês:
- Lambda + S3 + CloudWatch ≈ $1-2/mês
- Maioria coberta pelo free tier

### Monitoramento
- **CloudWatch Logs**: Erros e execuções
- **Métricas**: Duração e taxa de sucesso

### CI/CD
- GitHub Actions para deploy automático
- Terraform para infraestrutura como código
         │  4. Update Lambda              │
         └────────────────────────────────┘
```

### Fluxo de Execução

1. **Trigger**: Arquivo CSV é carregado no S3 Input Bucket
2. **Event**: S3 Event Notification dispara Lambda
3. **Processamento**: Lambda lê CSV, processa linha a linha, gera JSON
4. **Armazenamento**: JSON é salvo no S3 Output Bucket
5. **Logging**: Todos os logs são enviados ao CloudWatch

---

## 3. Componentes da Infraestrutura

### 3.1 S3 Buckets
- **Input Bucket**: Armazena arquivos CSV de entrada
- **Output Bucket**: Armazena JSON processados
- **Versionamento**: Habilitado para recuperação de dados
- **Encryption**: SSE-S3 (Server-Side Encryption)
- **Lifecycle**: Opcional - arquivar dados antigos para Glacier

### 3.2 AWS Lambda
- **Runtime**: Python 3.10
- **Deployment**: Container Image (ECR)
- **Memory**: 512 MB (ajustável)
- **Timeout**: 5 minutos (ajustável até 15 min)
- **Environment Variables**: Bucket names, configurações

### 3.3 IAM (Principle of Least Privilege)
- **Lambda Execution Role**:
  - `s3:GetObject` no input bucket
  - `s3:PutObject` no output bucket
  - `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
- **Sem permissões**: Delete, List (exceto necessário), outros serviços

### 3.4 CloudWatch
- **Log Group**: `/aws/lambda/csv-processor`
- **Retention**: 7 dias (configurável)
- **Metrics**: Duração, invocações, erros

### 3.5 ECR (Elastic Container Registry)
- **Repository**: Armazena imagem Docker da aplicação
- **Lifecycle Policy**: Manter últimas 5 imagens

---

## 4. Segurança

### Práticas Implementadas

1. **IAM Least Privilege**
   - Policies granulares por recurso
   - Sem uso de `*` em resources
   - Conditions baseadas em source

2. **Encryption**
   - S3: Server-Side Encryption (SSE-S3)
   - ECR: Encryption at rest
   - Secrets: AWS Secrets Manager (se necessário)

3. **Network**
   - Lambda em VPC (opcional, se necessário acesso privado)
   - Security Groups restritivos

4. **Monitoring**
   - CloudWatch Alarms para erros
   - AWS CloudTrail para auditoria
   - X-Ray para tracing (opcional)

---

## 5. Custos Estimados

### Cenário: 1000 processamentos/mês

| Serviço | Uso | Custo Mensal |
|---------|-----|--------------|
| Lambda | 1000 invocações × 30s × 512MB | ~$0.50 |
| S3 | 1GB storage + requests | ~$0.10 |
| ECR | 500MB imagem | ~$0.05 |
| CloudWatch | Logs + Metrics | ~$0.50 |
| **Total** | | **~$1.15/mês** |

**Comparação com Fargate:**
- Fargate (0.5 vCPU, 1GB RAM, 24/7): ~$30/mês
- **Lambda é ~26x mais barato** para este workload

---

## 6. Observabilidade

### Logs
- **CloudWatch Logs**: Todos os prints e erros da aplicação
- **Lambda Insights**: Métricas de cold start, memory usage
- **Structured Logging**: JSON format para melhor parsing

### Métricas
- Invocações por dia/hora
- Duração média de execução
- Taxa de erro
- Tamanho de arquivos processados

### Alertas
- Taxa de erro >5%
- Duração >3 minutos
- Throttling de Lambda

---

## 7. Melhorias Futuras

1. **Dead Letter Queue (DLQ)**: Para reprocessar falhas
2. **Step Functions**: Orquestrar múltiplas transformações
3. **Lambda Layers**: Compartilhar dependências
4. **S3 Batch Operations**: Processar múltiplos arquivos em paralelo
5. **API Gateway**: Trigger manual via API REST
6. **EventBridge**: Scheduling e event routing avançado

---

## Conclusão

A escolha do **AWS Lambda** é ideal para esta aplicação devido ao:
- Workload event-driven e intermitente
- Baixo custo operacional
- Simplicidade de implementação e manutenção
- Escalabilidade automática
- Adequação ao processamento batch/streaming

A arquitetura serverless permite focar na lógica de negócio, reduzindo complexidade operacional e custos.