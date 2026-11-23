<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./apps/cliente
├── docker-compose.yml
├── .env
├── .env.example
└── README.md

1 directory, 4 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# URL da API e do Site (necessárias no Build para o Next.js injetar nas páginas)
NEXT_PUBLIC_API_URL=https://api.francsilva.com.br
NEXT_PUBLIC_SITE_URL=https://francsilva.com.br

# Porta e Host de Execução do Servidor Node (opcionais, o Dockerfile já tem padrões)
PORT=3000
HOSTNAME=0.0.0.0

# Se o seu servidor precisar de variáveis secretas adicionais em tempo de execução, adicione abaixo:
# CHAVE_SECRETA_API=sua_chave_aqui
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 23/11/2026_
<!-- END_ID:bloco_final -->
