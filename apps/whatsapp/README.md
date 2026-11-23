<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./apps/whatsapp
├── docker-compose.yml
├── Dockerfile
├── .env
├── .env.example
└── README.md

1 directory, 5 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
#Url da API principal Django
API_HOST=api.seu-dominio.com


#Whatsapp Api
FB_CLIENT_ID=
FB_CLIENT_SECRET=
FB_REDIRECT_URI=
FB_CONFIG_ID=
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 23/11/2026_
<!-- END_ID:bloco_final -->
