<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

# Configurar as variaveis de ambiente ``.env``
Confifure as variáveis de ambiente seguindo os modelos de exemplo de cada ``.env.example``. de acordo com o que deseja. 

<!-- START_ID:bloco_variaveis -->
```bash
./apps
├── cliente
│   └── .env.example
├── gvendas
│   └── .env.example
├── media
│   └── .env.example
├── n8n
│   └── .env.example
├── netdata
│   └── .env.example
├── sftp
│   └── .env.example
├── sgn
│   └── .env.example
├── storage
│   └── .env.example
├── videos
│   └── .env.example
└── whatsapp
    └── .env.example

11 directories, 10 files
```
<!-- END_ID:bloco_variaveis -->

# Estrutura de pastas do projeto
<!-- START_ID:bloco_estrutura -->
```bash
./apps
├── cliente
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   └── README.md
├── contabilidade
│   ├── docker-compose.yml
│   ├── .env
│   └── README.md
├── gvendas
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── .env
│   ├── .env.example
│   ├── nginx.conf
│   └── README.md
├── media
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   ├── nginx.conf
│   └── README.md
├── n8n
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   └── README.md
├── netdata
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   └── README.md
├── pdf
│   ├── src
│   │   ├── templates
│   │   ├── pdf.js
│   │   └── server.js
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── .env
│   ├── package.json
│   ├── package-lock.json
│   └── README.md
├── sftp
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   └── README.md
├── sgn
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   └── README.md
├── storage
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── nginx.conf
│   └── README.md
├── videos
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   └── README.md
├── whatsapp
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── .env
│   ├── .env.example
│   └── README.md
├── auth-nginx.conf
├── docker-compose.yml
└── README.md

15 directories, 59 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# --- INFRAESTRUTURA ---
API_DOMAIN=dominio_da_api
MEDIA_DOMAIN=dominio_de_medias
STORAGE_DOMAIN=dominio_do_storage


# --- CONTAINER WHATSAPP ---
WHATSAPP_CONTAINER=whatsapp
WHATSAPP_CONTAINER_PORT=3000
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 23/11/2026_
<!-- END_ID:bloco_final -->
