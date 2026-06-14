<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

## 🚀 Preparação da VPS
**Comando de execução direta:**
```bash
apt update && apt install -y curl && curl -sSL https://raw.githubusercontent.com/amazoniacentral/docker-vps/main/setup.sh | sudo bash
```
**Documentação:** [amazoniacentral/docker-vps](https://github.com/amazoniacentral/docker-vps)

## 🔐 Autenticação no GitHub
* Gerar e Adicionar a Chave SSH Se você ainda não tem uma chave ou o GitHub não a conhece, faça isso:
1. Gerar a chave (dê ENTER em tudo):
```bash
ssh-keygen -t ed25519 -C "docker-vps"
```

2. Copiar a chave gerada:
```baah
cat ~/.ssh/id_ed25519.pub
```

3. Adicione esta chave no seu GitHub em: **Settings -> Deploy Keys** (no repositório) ou em **Settings -> SSH and GPG keys** (na sua conta).
Após essa configuração, pode usar o git com ssh

## 🏗️ Instalação da Estrutura FSilva Cloud
1. Clonar os repositórios:
```bash
mkdir -p /opt/fsilva-cloud && cd /opt/fsilva-cloud && git clone --recursive git@github.com:amazoniacentral/fsilva-cloud.git . 
```
2. Configurar as variaveis de ambiente ``.env``
Confifure as variáveis de ambiente seguindo os modelos de exemplo de cada ``.env.example``.

<!-- START_ID:bloco_variaveis -->
```bash
.
├── apps
│   ├── gvendas
│   │   └── .env.example
│   ├── media
│   │   └── .env.example
│   ├── n8n
│   │   └── .env.example
│   ├── netdata
│   │   └── .env.example
│   ├── sgn
│   │   └── .env.example
│   ├── storage
│   │   └── .env.example
│   ├── whatsapp
│   │   └── .env.example
│   └── .env.example
├── database
│   └── .env.example
├── proxy
│   ├── traefik
│   │   └── .env.example
│   └── tunnel
│       └── .env.example
├── scripts
│   └── .env.example
└── server
    ├── dev
    │   └── .env.example
    └── prod
        └── .env.example

17 directories, 14 files
```
<!-- END_ID:bloco_variaveis -->

3. Criar e subir os containers

```bash
bash scripts/deploy/setup.sh
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
│   ├── n8n
│   │   ├── .env.example
│   │   ├── README.md
│   │   └── docker-compose.n8n.yml
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
│   │   ├── setup.sh
│   │   └── variaveis.sh
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
│   │   ├── traefik.dev.yml
│   │   └── tunnel.dev.yml
│   ├── prod
│   │   ├── .env.example
│   │   ├── README.md
│   │   ├── docker-compose.prod.yml
│   │   ├── host.prod.yml
│   │   ├── traefik.prod.yml
│   │   └── tunnel.prod.yml
│   ├── README.md
│   └── docker-compose.server.yml
├── .gitignore
├── .gitmodules
├── README.md
├── colocarnosfilhos.yml.info
├── dump.rdb
├── host.dev.yml
├── host.prod.yml
├── traefik.dev.yml
├── traefik.prod.yml
├── tunnel.dev.yml
└── tunnel.prod.yml

27 directories, 107 files
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

_Atualizado em: 14/06/2026_
<!-- END_ID:bloco_final -->
