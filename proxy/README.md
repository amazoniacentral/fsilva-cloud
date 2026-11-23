<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

## Configurar as variaveis de ambiente ``.env``
Confifure as variáveis de ambiente seguindo os modelos de exemplo de cada ``.env.example``. de acordo com o que deseja. 

<!-- START_ID:bloco_variaveis -->
```bash
./proxy
├── cloudflare
│   └── .env.example
├── local
│   └── .env.example
└── tunnel
    └── .env.example

4 directories, 3 files
```
<!-- END_ID:bloco_variaveis -->

## Estrurura de pastas
<!-- START_ID:bloco_estrutura -->
```bash
./proxy
├── cloudflare
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   └── README.md
├── errors
│   ├── html
│   │   ├── 400.html
│   │   ├── 401.html
│   │   ├── 403.html
│   │   ├── 404.html
│   │   ├── 500.html
│   │   ├── 502.html
│   │   ├── 503.html
│   │   └── 504.html
│   ├── docker-compose.yml
│   ├── errors-global.yml
│   ├── nginx.conf
│   └── README.md
├── .htpasswd
├── local
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   └── README.md
├── services
│   ├── docker-compose.traefik.yml
│   ├── docker-compose.tunnel.yml
│   ├── .env
│   └── README.md
├── tunnel
│   ├── docker-compose.traefik.yml
│   ├── docker-compose.yml
│   ├── .env
│   ├── .env.example
│   └── README.md
└── README.md

8 directories, 30 files
```
<!-- END_ID:bloco_estrutura -->

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 23/11/2026_
<!-- END_ID:bloco_final -->
