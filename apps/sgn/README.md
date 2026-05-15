<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./apps/sgn
├── .env.example
├── Dockerfile
├── README.md
├── docker-compose.sgn.yml
└── nginx.conf

1 directory, 5 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# --- INFRAESTRUTURA ---
#API_DOMAIN=api.seusite.com
#MEDIA_DOMAIN=cdn-media.seusite.com
#STORAGE_DOMAIN=storage-private.seusite.com

# --- SERVIÇO WHATSAPP ---
#WHATSAPP_CONTAINER=whatsapp
#WHATSAPP_CONTAINER_PORT=3000

# --- CONFIGURAÇÕES BÁSICAS DO DJANGO ---
#SECRET_KEY=sua_chave_secreta_aqui
DEBUG=False
#ALLOWED_HOSTS=gvendas.app.br,api.gvendas.app.br,localhost

# --- BANCO DE DADOS (DATABASE_URL) ---
# Formato: postgres://usuario:senha@host:porta/nome_do_banco
DATABASE_URL=sua_conexao_banco_de_dados_prod

# --- SEGURANÇA E DOMÍNIOS ---
# Domínios adicionais para bloquear (separados por vírgula)
BANNED_DOMAINS=exemplo.com,proibido.net

# --- INTEGRAÇÕES DE PAGAMENTO ---
#TOKEN_APLICATION_PAGBANK=seu_token_aqui
#PAGSEGURO_CLIENT_ID=gvendas
#PAGSEGURO_CLIENT_SECRET=5FE20D8BCCCCC65AA4FC9FAED02836D8

# --- APIS EXTERNAS ---
#GOOGLE_API_KEY=AIzaSyAg-c1FKLHKp4mWCvI_t8POfLXWQtQbix0
#GTIN_RSCISTEMAS_BASIC=ZnJhbmNpc2Nvc2lsdmE6U2Ftc3VuZzEyMw==

# --- FILAS E CACHE (CELERY / REDIS) ---
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_TASK_DEFAULT_QUEUE=prod_queue

# --- NOTIFICAÇÕES PUSH PWA ---
#VAPID_PRIVATE_KEY=sua_chave_vapid_privada

# --- NOTIFICAÇÕES (FIREBASE) ---
#FIREBASE_SERVICE_ACCOUNT=volumes/certificados
#FIREBASE_PROJECT_ID=id-do-projeto-firebase
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 15/05/2026_
<!-- END_ID:bloco_final -->
