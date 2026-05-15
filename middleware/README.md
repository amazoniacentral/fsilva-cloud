<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./middleware
├── errors
│   ├── html
│   │   ├── 404.html
│   │   └── 500.html
│   ├── README.md
│   ├── docker-compose.errors.yml
│   └── nginx.conf
├── README.md
└── docker-compose.middleware.yml

3 directories, 7 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# Configurações de Domínio
DOMAIN=netdata.seu-dominio.com
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 15/05/2026_
<!-- END_ID:bloco_final -->
