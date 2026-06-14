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
├── .env.example
├── README.md
└── docker-compose.n8n.yml

1 directory, 3 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# n8n pra ser acessado apenas pelo localhost
HOST=127.0.0.1
PORT_N8N=5678
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 14/06/2026_
<!-- END_ID:bloco_final -->
