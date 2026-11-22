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
└── local
    └── .env.example

3 directories, 2 files
```
<!-- END_ID:bloco_variaveis -->

## Estrurura de pastas
<!-- START_ID:bloco_estrutura -->
```bash
./proxy
├── cloudflare
│   ├── docker-compose.yml
│   └── .env.example
├── errors
│   ├── html
│   │   ├── 404.html
│   │   └── 500.html
│   ├── docker-compose.yml
│   ├── nginx.conf
│   └── README.md
├── local
│   ├── docker-compose.yml
│   └── .env.example
├── services
│   ├── docker-compose.traefik.yml
│   ├── docker-compose.tunnel.yml
│   └── .env
├── tunnel
│   ├── docker-compose.traefik.yml
│   ├── docker-compose.yml
│   └── .env
└── README.md

7 directories, 16 files
```
<!-- END_ID:bloco_estrutura -->

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 22/11/2026_
<!-- END_ID:bloco_final -->
