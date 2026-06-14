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
├── gvendas
│   └── .env.example
├── media
│   └── .env.example
├── n8n
│   └── .env.example
├── netdata
│   └── .env.example
├── sgn
│   └── .env.example
├── storage
│   └── .env.example
├── whatsapp
│   └── .env.example
└── .env.example

8 directories, 8 files
```
<!-- END_ID:bloco_variaveis -->

# Estrutura de pastas do projeto
<!-- START_ID:bloco_estrutura -->
```bash
./apps
├── gvendas
│   ├── .env.example
│   ├── Dockerfile
│   ├── README.md
│   ├── docker-compose.gvendas.yml
│   └── nginx.conf
├── media
│   ├── .env.example
│   ├── README.md
│   ├── docker-compose.media.yml
│   └── nginx.conf
├── n8n
│   ├── .env.example
│   ├── README.md
│   └── docker-compose.n8n.yml
├── netdata
│   ├── .env.example
│   ├── README.md
│   └── docker-compose.netdata.yml
├── sgn
│   ├── .env.example
│   ├── Dockerfile
│   ├── README.md
│   ├── docker-compose.sgn.yml
│   └── nginx.conf
├── storage
│   ├── .env.example
│   ├── README.md
│   ├── docker-compose.storage.yml
│   ├── nginx.conf
│   └── nginx2.conf
├── whatsapp
│   ├── .env.example
│   ├── Dockerfile
│   ├── README.md
│   └── docker-compose.whatsapp.yml
├── .env.example
├── README.md
├── auth-nginx.conf
└── docker-compose.apps.yml

8 directories, 33 files
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

_Atualizado em: 14/06/2026_
<!-- END_ID:bloco_final -->
