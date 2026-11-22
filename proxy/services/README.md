<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./proxy/services
├── docker-compose.traefik.yml
├── docker-compose.tunnel.yml
├── .env
└── README.md

1 directory, 4 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
#Dominio das Midias

MEDIA_DOMAIN=seu_dominio_media
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 22/11/2026_
<!-- END_ID:bloco_final -->
