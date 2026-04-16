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
├── database
│   ├── .env.example
│   ├── README.md
│   ├── docker-compose.postgres.yml
│   └── docker-compose.redis.yml
├── gvendas-suite
│   ├── app-react
│   │   ├── Dockerfile
│   │   ├── default.conf
│   │   └── docker-compose.react.yml
│   ├── msg-node
│   │   ├── .env.example
│   │   ├── Dockerfile
│   │   └── docker-compose.node.yml
│   ├── sgn-django
│   │   ├── .env.example
│   │   ├── Dockerfile
│   │   ├── docker-compose.django.yml
│   │   └── nginx.conf
│   └── README.md
├── netdata
│   ├── .env.example
│   ├── README.md
│   └── docker-compose.netdata.yml
├── proxy
│   ├── dynamic
│   ├── .env.example
│   ├── README.md
│   └── docker-compose.traefik.yml
├── repos
│   ├── docker-vps
│   ├── gvendas
│   ├── push
│   ├── sgn
│   └── README.md
├── scripts
│   ├── estrutura.sh
│   └── install.sh
├── .gitignore
├── .gitmodules
├── README.md
├── colocarnosfilhos.yml
└── docker-compose.yml

15 directories, 29 files
```


## Outras configurações
* [**Banco de Dados:**](database/README.md)
* [**GVendas Suite:**](gvendas-suite/README.md)
* [**Proxy:**](proxy/README.md)
* [**Monitoramento:**](netdata/README.md)
* [**Módulos:**](repos/README.md)
* [**Scripts geral:**](scripts/)
---
**Desenvolvido por Francisco Silva (FSilva) — 2026**
