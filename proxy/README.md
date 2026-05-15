<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

# Proxy para acesso a web

[proxy/traefik/.env](traefik/.env.example)
```.env
# Gerar Certificado Let's
ACME_EMAIL=seu-email@dominio.com
#Painel do Traefik
DOMAIN=traefik.seu-dominio.com
```

[proxy/tunnel/.env](tunnel/.env.example)
```.env
# Configurações de Tunel
TUNNEL_TOKEN=seu_token_aqui_sem_aspas
```
  
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

_Atualizado em: 14/05/2026_
<!-- END_ID:bloco_final -->
