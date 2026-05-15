<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

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

7 directories, 30 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# --- INFRAESTRUTURA ---
#API_DOMAIN=dominio_da_api
#MEDIA_DOMAIN=dominio_de_medias
#STORAGE_DOMAIN=dominio_do_storage


# --- CONTAINER WHATSAPP ---
#WHATSAPP_CONTAINER=whatsapp
#WHATSAPP_CONTAINER_PORT=3000
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 14/05/2026_
<!-- END_ID:bloco_final -->
