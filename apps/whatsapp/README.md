<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./apps/whatsapp
├── .env.example
├── Dockerfile
├── README.md
└── docker-compose.whatsapp.yml

1 directory, 4 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# Aplicação
HOST=0.0.0.0
PORT=3000

# Servidor Api
API_HOST=django-srv
API_PORT=8000

# Origens permitidas (separadas por vírgula)
ALLOWED_ORIGINS=*

SECRET_KEY=<seu token de identificação com o sevidor Api>
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 14/06/2026_
<!-- END_ID:bloco_final -->
