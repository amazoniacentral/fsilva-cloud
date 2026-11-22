<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./proxy/cloudflare
├── docker-compose.yml
├── .env.example
└── README.md

1 directory, 3 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# E-mail para registro do certificado Let's Encrypt
ACME_EMAIL=seu_email@dominio.com

# Credenciais da API da Cloudflare para o DNS Challenge
CF_API_EMAIL=seu_email@dominio.com
CF_API_KEY=sua_global_api_key_da_cloudflare_aqui
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 22/11/2026_
<!-- END_ID:bloco_final -->
