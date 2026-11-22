<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

## Configurar as variaveis de ambiente ``.env``
Confifure as variáveis de ambiente seguindo os modelos de exemplo de cada ``.env.example``. de acordo com o que deseja. 
Aqui é o local onde vai fazer as substituições das variáveis, ou seja, qualquer variável já preenchidas, se repetir aqui sera substituida por essas novas.

<!-- START_ID:bloco_variaveis -->
```bash
./server
├── dev
│   └── .env.example
└── prod
    └── .env.example

3 directories, 2 files
```
<!-- END_ID:bloco_variaveis -->

## Estrutura da pasta:
Aqui é a estrutura de prod/dev

<!-- START_ID:bloco_estrutura -->
```bash
./server
├── dev
│   ├── docker-compose.cloudflare.yml
│   ├── docker-compose.local.yml
│   ├── docker-compose.tunnel.yml
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
├── prod
│   ├── docker-compose.cloudflare.yml
│   ├── docker-compose.local.yml
│   ├── docker-compose.tunnel.yml
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
└── README.md

3 directories, 13 files
```
<!-- END_ID:bloco_estrutura -->

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 22/11/2026_
<!-- END_ID:bloco_final -->
