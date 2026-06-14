<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./server/dev
├── .env.example
├── README.md
├── docker-compose.dev.yml
├── host.dev.yml
├── traefik.dev.yml
└── tunnel.dev.yml

1 directory, 6 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
#Aqui coloca todas as variaveis que deseja substituir para desenvolvimento

# --- INFRAESTRUTURA ---
#API_DOMAIN=dominio_da_api
#MEDIA_DOMAIN=dominio_de_medias
#STORAGE_DOMAIN=dominio_do_storage


# --- CONTAINER WHATSAPP ---
#WHATSAPP_CONTAINER=whatsapp
#WHATSAPP_CONTAINER_PORT=3000


# --- FILAS E CACHE (CELERY / REDIS) ---
CELERY_BROKER_URL=redis://redis:6379/1
CELERY_TASK_DEFAULT_QUEUE=dev_queue

# --- BANCO DE DADOS DEV (DATABASE_URL) ---
# Formato: postgres://usuario:senha@host:porta/nome_do_banco
DATABASE_URL=sua_conexao_banco_de_dados_dev

# --- DJANGO ---
DEBUG=True
ALLOWED_HOSTS=localhost
CSRF_TRUSTED_ORIGINS=localhost:8080


# Configurações de Tunel
TUNNEL_TOKEN=seu_token_aqui_sem_aspas
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 14/06/2026_
<!-- END_ID:bloco_final -->
