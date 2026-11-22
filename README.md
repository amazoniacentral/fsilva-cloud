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
│   ├── cliente
│   │   └── .env.example
│   ├── gvendas
│   │   └── .env.example
│   ├── media
│   │   └── .env.example
│   ├── n8n
│   │   └── .env.example
│   ├── netdata
│   │   └── .env.example
│   ├── sftp
│   │   └── .env.example
│   ├── sgn
│   │   └── .env.example
│   ├── storage
│   │   └── .env.example
│   ├── videos
│   │   └── .env.example
│   └── whatsapp
│       └── .env.example
├── database
│   └── .env.example
├── proxy
│   ├── cloudflare
│   │   └── .env.example
│   └── local
│       └── .env.example
├── scripts
│   └── .env.example
└── server
    ├── dev
    │   └── .env.example
    └── prod
        └── .env.example

20 directories, 16 files
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
│   ├── cliente
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   ├── .env.example
│   │   └── README.md
│   ├── contabilidade
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── README.md
│   ├── gvendas
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   ├── entrypoint.sh
│   │   ├── .env
│   │   ├── .env.example
│   │   ├── nginx.conf
│   │   └── README.md
│   ├── media
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   ├── .env.example
│   │   ├── nginx.conf
│   │   └── README.md
│   ├── n8n
│   │   ├── docker-compose.yml
│   │   ├── .env.example
│   │   └── README.md
│   ├── netdata
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   ├── .env.example
│   │   └── README.md
│   ├── pdf
│   │   ├── src
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   ├── .env
│   │   ├── package.json
│   │   ├── package-lock.json
│   │   └── README.md
│   ├── sftp
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   ├── .env.example
│   │   └── README.md
│   ├── sgn
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   ├── .env.example
│   │   ├── nginx.conf
│   │   └── README.md
│   ├── storage
│   │   ├── docker-compose.yml
│   │   ├── .env.example
│   │   ├── nginx.conf
│   │   └── README.md
│   ├── videos
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   ├── .env.example
│   │   └── README.md
│   ├── whatsapp
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   ├── .env
│   │   ├── .env.example
│   │   └── README.md
│   ├── auth-nginx.conf
│   ├── docker-compose.yml
│   └── README.md
├── database
│   ├── docker-compose.pgadmin.yml
│   ├── docker-compose.postgres.yml
│   ├── docker-compose.redis.yml
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── .env.example
│   └── README.md
├── proxy
│   ├── cloudflare
│   │   ├── docker-compose.yml
│   │   ├── .env.example
│   │   └── README.md
│   ├── errors
│   │   ├── html
│   │   ├── docker-compose.yml
│   │   ├── nginx.conf
│   │   └── README.md
│   ├── local
│   │   ├── docker-compose.yml
│   │   ├── .env.example
│   │   └── README.md
│   ├── services
│   │   ├── docker-compose.traefik.yml
│   │   ├── docker-compose.tunnel.yml
│   │   ├── .env
│   │   └── README.md
│   ├── tunnel
│   │   ├── docker-compose.traefik.yml
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── README.md
│   └── README.md
├── scripts
│   ├── backup
│   │   ├── gdrive
│   │   ├── r2
│   │   └── README.md
│   ├── database
│   │   ├── database.sh
│   │   ├── extensao_vetor.sh
│   │   ├── indicesn8n.sh
│   │   ├── README.md
│   │   └── restaurar.sh
│   ├── deploy
│   │   ├── dev_update.sh
│   │   ├── prod_update.sh
│   │   ├── README.md
│   │   └── setup.sh
│   ├── documentacao
│   │   ├── blocos.sh
│   │   ├── cabecalho.sh
│   │   ├── estrutura.sh
│   │   ├── README.md
│   │   ├── rodape.sh
│   │   ├── setup.sh
│   │   └── variaveis.sh
│   ├── git
│   │   ├── commit.sh
│   │   ├── README.md
│   │   ├── setup.sh
│   │   ├── submodule_adicionar.sh
│   │   ├── submodule_branch.sh
│   │   ├── submodule_listar.sh
│   │   ├── submodule_remover.sh
│   │   └── tags.sh
│   ├── alias.sh
│   ├── clean.sh
│   ├── containers.sh
│   ├── copy.sh
│   ├── crontab.sh
│   ├── .env.example
│   ├── haskey.sh
│   ├── ia.sh
│   ├── install.sh
│   ├── ipv6.sh
│   ├── limpar_traefik.sh
│   ├── otimizar_rede.sh
│   ├── README.md
│   ├── reset.sh
│   ├── setup_reclone.sh
│   └── status.sh
├── server
│   ├── dev
│   │   ├── docker-compose.cloudflare.yml
│   │   ├── docker-compose.local.yml
│   │   ├── docker-compose.tunnel.yml
│   │   ├── docker-compose.yml
│   │   ├── .env.example
│   │   └── README.md
│   ├── prod
│   │   ├── docker-compose.cloudflare.yml
│   │   ├── docker-compose.local.yml
│   │   ├── docker-compose.tunnel.yml
│   │   ├── docker-compose.yml
│   │   ├── .env.example
│   │   └── README.md
│   └── README.md
├── dump.rdb
├── .gitignore
├── README.md
└── setup.sh

34 directories, 140 files
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

_Atualizado em: 22/11/2026_
<!-- END_ID:bloco_final -->
