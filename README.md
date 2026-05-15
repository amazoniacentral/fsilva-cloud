<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

## 🚀 Instalação Rápida na VPS
* **Repositório:** [amazoniacentral/docker-vps](https://github.com/amazoniacentral/docker-vps)

**Comando de execução direta:**
```bash
apt update && apt install -y curl && curl -sSL https://raw.githubusercontent.com/amazoniacentral/docker-vps/main/setup.sh | sudo bash
```

## 🔐 Autenticação no GitHub
O script acima prepara a VPS e gera uma chave SSH para que a VPS possa baixar seus repositórios privados e submódulos sem pedir senha.

1. Copie a chave pública gerada:
```bash
cat ~/.ssh/id_ed25519.pub
```

2. Adicione esta chave no seu GitHub em: **Settings -> Deploy Keys** (no repositório) ou em **Settings -> SSH and GPG keys** (na sua conta).

## 🏗️ Instalação da Estrutura FSilva Cloud
Após configurar a chave no GitHub, execute o instalador da stack para clonar os repositórios e subir os containers:

```bash
mkdir -p /opt/fsilva-cloud && cd /opt/fsilva-cloud && git clone --recursive git@github.com:amazoniacentral/fsilva-cloud.git . && chmod +x scripts/install.sh && ./scripts/install.sh
```

## Estrutura do projeto 
Aqui está a estrutura de arquivos do projeto fsilva-cloud
<!-- START_ID:bloco_estrutura -->
```bash
.
├── apps
│   ├── gvendas
│   │   ├── .env.example
│   │   ├── Dockerfile
│   │   ├── README.md
│   │   ├── docker-compose.gvendas.yml
│   │   └── nginx.conf
│   ├── media
│   │   ├── .env.example
│   │   ├── README.md
│   │   ├── docker-compose.media.yml
│   │   └── nginx.conf
│   ├── netdata
│   │   ├── .env.example
│   │   ├── README.md
│   │   └── docker-compose.netdata.yml
│   ├── sgn
│   │   ├── .env.example
│   │   ├── Dockerfile
│   │   ├── README.md
│   │   ├── docker-compose.sgn.yml
│   │   └── nginx.conf
│   ├── storage
│   │   ├── .env.example
│   │   ├── README.md
│   │   ├── docker-compose.storage.yml
│   │   ├── nginx.conf
│   │   └── nginx2.conf
│   ├── whatsapp
│   │   ├── .env.example
│   │   ├── Dockerfile
│   │   ├── README.md
│   │   └── docker-compose.whatsapp.yml
│   ├── .env.example
│   ├── README.md
│   ├── auth-nginx.conf
│   └── docker-compose.apps.yml
├── database
│   ├── .env.example
│   ├── README.md
│   ├── docker-compose.database.yml
│   ├── docker-compose.postgres.yml
│   └── docker-compose.redis.yml
├── middleware
│   ├── errors
│   │   ├── html
│   │   ├── README.md
│   │   ├── docker-compose.errors.yml
│   │   └── nginx.conf
│   ├── README.md
│   └── docker-compose.middleware.yml
├── proxy
│   ├── traefik
│   │   ├── .env.example
│   │   ├── README.md
│   │   ├── docker-compose.traefik.yml
│   │   └── servicos.yml
│   ├── tunnel
│   │   ├── .env.example
│   │   ├── README.md
│   │   ├── docker-compose.tunnel.yml
│   │   └── servicos.yml
│   └── README.md
├── repos
│   ├── docker-vps
│   ├── gvendas
│   ├── push
│   ├── sgn
│   └── README.md
├── scripts
│   ├── deploy
│   │   ├── README.md
│   │   ├── dev_update.sh
│   │   ├── prod_update.sh
│   │   └── setup.sh
│   ├── documentacao
│   │   ├── README.md
│   │   ├── blocos.sh
│   │   ├── cabecalho.sh
│   │   ├── estrutura.sh
│   │   ├── rodape.sh
│   │   └── setup.sh
│   ├── .env.example
│   ├── README.md
│   ├── alias.sh
│   ├── backup_db.sh
│   ├── backup_rclone.sh
│   ├── containers.sh
│   ├── crontab.sh
│   ├── database.sh
│   ├── db_baixar.sh
│   ├── gitmodules.sh
│   ├── haskey.sh
│   ├── install.sh
│   ├── limpar_traefik.sh
│   ├── otimizar_rede.sh
│   ├── reset.sh
│   ├── setup_reclone.sh
│   ├── status.sh
│   └── sync_rclone.sh
├── server
│   ├── dev
│   │   ├── .env.example
│   │   ├── README.md
│   │   ├── docker-compose.dev.yml
│   │   ├── host.dev.yml
│   │   └── tunnel.dev.yml
│   ├── prod
│   │   ├── .env.example
│   │   ├── README.md
│   │   ├── docker-compose.prod.yml
│   │   ├── host.prod.yml
│   │   └── tunnel.prod.yml
│   ├── README.md
│   └── docker-compose.server.yml
├── .gitignore
├── .gitmodules
├── README.md
├── colocarnosfilhos.yml.info
├── docker-compose.yml
├── dump.rdb
├── host.dev.yml
├── host.prod.yml
├── traefik.dev.yml
├── traefik.prod.yml
├── tunnel.dev.yml
└── tunnel.prod.yml

26 directories, 102 files
```
<!-- END_ID:bloco_estrutura -->



## Outras configurações
* [**Banco de Dados:**](database/README.md)
* [**Apps:**](apps/README.md)
* [**Proxy:**](proxy/README.md)
* [**Módulos:**](repos/README.md)
* [**Scripts Geral:**](scripts/README.md)
* [**Produção:**](server/prod/README.md)
* [**Developer:**](server/dev/README.md)


<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 15/05/2026_
<!-- END_ID:bloco_final -->
