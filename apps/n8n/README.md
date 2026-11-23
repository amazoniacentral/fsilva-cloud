<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

# 🚀 Guia rápido de uso do n8n

O n8n é uma ferramenta de automação de workflows que permite conectar APIs, serviços e sistemas sem precisar escrever muito código.

---

## 📌 O que é o n8n?

O n8n é uma plataforma de automação visual onde você cria fluxos (workflows) conectando "nós" (nodes).

Cada node representa uma ação, como:
- Fazer uma requisição HTTP
- Enviar e-mail
- Salvar dados em banco
- Integrar com APIs (WhatsApp, Telegram, Stripe, etc.)

---

## ⚙️ Como funciona

Um workflow no n8n funciona assim:

1. **Trigger (gatilho)**  
   Ex: webhook, horário agendado, evento externo

2. **Nodes de processamento**  
   Ex: filtrar dados, transformar JSON, condições (IF)

3. **Ações finais**  
   Ex: enviar mensagem, salvar no banco, chamar API

---

## 🧩 Exemplo simples

### Fluxo: Webhook → Processar → Responder

- Webhook recebe uma requisição
- Function node formata os dados
- HTTP Response retorna o resultado

---

### Estrutura
<!-- START_ID:bloco_estrutura -->
```bash
./apps/n8n
├── docker-compose.yml
├── .env
├── .env.example
└── README.md

1 directory, 4 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# Configurações do Projeto e Domínio
COMPOSE_PROJECT_NAME=n8n
DEFAULT_DOMAIN=francsilva.com.br

# Configurações de Email (SMTP)
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=smtp.gmail.com
N8N_SMTP_PORT=587
N8N_SMTP_USER=example@gmail.com
N8N_SMTP_PASS=hshd hdgr sgdj shdy
N8N_SMTP_SENDER=N8N <no-reply@gvendas.app.br>

# Timezone e Segurança
TZ=America/Sao_Paulo
GENERIC_TIMEZONE=America/Sao_Paulo
N8N_ENCRYPTION_KEY=8935f4803dfbf1ec12c28d283a736d43cb6eef07b4138c143115e1db5239adc6

# Banco de Dados PostgreSQL
DB_TYPE=postgresdb
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=n8n
DB_POSTGRESDB_SCHEMA=public

# Configurações de Execução e Arquivos do n8n
N8N_EMAIL_MARCA_DAGUA=false
N8N_PROTOCOL=https
N8N_PROXY_TRUST=true
N8N_HOST=n8n.francsilva.com.br
N8N_WEBHOOK_URL=https://webhook.francsilva.com.br/
N8N_EDITOR_BASE_URL=https://n8n.francsilva.com.br/
EXECUTIONS_DATA_SAVE_ON_ERROR=all
N8N_RESTRICT_FILE_ACCESS_TO="/home/node/files/"
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=redis
QUEUE_BULL_REDIS_PORT=6379
OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_MAX_AGE=24
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
```
Para acessar são duas urls
Editor - https://n8n.seu-dominio.com
Webrooks - https://webhook.seu-dominio.com

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 23/11/2026_
<!-- END_ID:bloco_final -->
