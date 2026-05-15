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
├── traefik
│   └── .env.example
└── tunnel
    └── .env.example

3 directories, 2 files
```
<!-- END_ID:bloco_variaveis -->

## Estrurura de pastas
<!-- START_ID:bloco_estrutura -->
```bash
./proxy
├── traefik
│   ├── .env.example
│   ├── README.md
│   ├── docker-compose.traefik.yml
│   └── servicos.yml
├── tunnel
│   ├── .env.example
│   ├── README.md
│   ├── docker-compose.tunnel.yml
│   └── servicos.yml
└── README.md

3 directories, 9 files
```
<!-- END_ID:bloco_estrutura -->

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 15/05/2026_
<!-- END_ID:bloco_final -->
