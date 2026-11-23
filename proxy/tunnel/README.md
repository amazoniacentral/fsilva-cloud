<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./proxy/tunnel
├── docker-compose.traefik.yml
├── docker-compose.yml
├── .env
├── .env.example
└── README.md

1 directory, 5 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# ==========================================
# Configuração do Cloudflare Tunnel
# ==========================================

# Token de autenticação do túnel fornecido pelo painel do Cloudflare Zero Trust
# (Obtenha esse token no dashboard do Cloudflare ao criar/configurar o Tunnel)
TUNNEL_TOKEN=seu_cloudflare_tunnel_token_aqui

# Opcional: ID do túnel caso prefira usar arquivo de credenciais json em vez do token direto
# TUNNEL_ID=seu-uuid-do-tunel-aqui

# Credenciais para o painel do Traefik
TRAEFIK_USER=admin
TRAEFIK_DASHBOARD_ENABLE=true
TRAEFIK_AUTH=admin:$2y$05$ExemploDeHashBcryptGeradoAutomaticamente...
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 23/11/2026_
<!-- END_ID:bloco_final -->
