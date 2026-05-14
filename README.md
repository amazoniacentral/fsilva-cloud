# FSilva Cloud
Stack central de orquestração e infraestrutura para o ecossistema FSilva. Gerencia o projeto GVendas e serviços de terceiros via Docker Compose e Git Submodules.

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
```estrutura
..
├── apps
│   ├── gvendas
│   │   ├── .env.example
│   │   ├── Dockerfile
│   │   ├── docker-compose.gvendas.yml
│   │   └── nginx.conf
│   ├── media
│   │   ├── .env.example
│   │   ├── docker-compose.media.yml
│   │   └── nginx.conf
│   ├── netdata
│   │   ├── .env.example
│   │   ├── README.md
│   │   └── docker-compose.netdata.yml
│   ├── sgn
│   │   ├── .env.example
│   │   ├── Dockerfile
│   │   ├── docker-compose.sgn.yml
│   │   └── nginx.conf
│   ├── storage
│   │   ├── .env.example
│   │   ├── docker-compose.storage.yml
│   │   ├── nginx.conf
│   │   └── nginx2.conf
│   ├── whatsapp
│   │   ├── .env.example
│   │   ├── Dockerfile
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
│   │   ├── docker-compose.errors.yml
│   │   └── nginx.conf
│   └── docker-compose.middleware.yml
├── proxy
│   ├── traefik
│   │   ├── .env.example
│   │   ├── docker-compose.traefik.yml
│   │   └── servicos.yml
│   ├── tunnel
│   │   ├── .env.example
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
│   ├── .env.exemplo
│   ├── README.md
│   ├── alias.sh
│   ├── backup_db.sh
│   ├── backup_rclone.sh
│   ├── containers.sh
│   ├── crontab.sh
│   ├── database.sh
│   ├── db_baixar.sh
│   ├── estrutura.sh
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
│   │   ├── docker-compose.dev.yml
│   │   ├── host.dev.yml
│   │   └── tunnel.dev.yml
│   ├── prod
│   │   ├── .env.example
│   │   ├── docker-compose.prod.yml
│   │   ├── host.prod.yml
│   │   └── tunnel.prod.yml
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

24 directories, 81 files
```


## Outras configurações
* [**Banco de Dados:**](database/README.md)
* [**Apps:**](apps/README.md)
* [**Proxy:**](proxy/README.md)
* [**Módulos:**](repos/README.md)
* [**Scripts Geral:**](scripts/README.md)
* [**Produção:**](server/prod/README.md)
* [**Developer:**](server/dev/README.md)
---
**Desenvolvido por Francisco Silva (FSilva) — 2026**
