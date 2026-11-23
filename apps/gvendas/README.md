<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./apps/gvendas
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
├── .env
├── .env.example
├── nginx.conf
└── README.md

1 directory, 7 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
#Dominio da API
API_DOMAIN=api.seu-dominio.com


#WHATSAPP META Api Oficial
META_APP_ID=sua_chave_meta_app_id
CONFIG_ID=sua_chave_meta_config
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 23/11/2026_
<!-- END_ID:bloco_final -->
