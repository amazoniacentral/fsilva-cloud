# FSilva Cloud
Stack central de orquestração e infraestrutura para o ecossistema FSilva. Gerencia o projeto GVendas e serviços de terceiros via Docker Compose e Git Submodules.

## 🚀 Instalação Rápida na VPS
* **Repositório:** [amazoniacentral/docker-vps](https://github.com/amazoniacentral/docker-vps)

**Comando de execução direta:**
```bash
apt update && apt install -y curl && curl -sSL https://raw.githubusercontent.com/amazoniacentral/docker-vps/main/preparar_vps.sh | sudo bash
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
│   └── sgn-django
│       ├── .env.example
│       ├── Dockerfile
│       ├── docker-compose.django.yml
│       └── nginx.conf
├── netdata
│   ├── .env.example
│   └── docker-compose.netdata.yml
├── proxy
│   ├── dynamic
│   ├── .env.example
│   └── docker-compose.traefik.yml
├── repos
│   ├── docker-vps
│   ├── gvendas
│   ├── push
│   └── sgn
├── scripts
│   ├── estrutura.sh
│   └── install.sh
├── .gitignore
├── .gitmodules
├── README.md
├── colocarnosfilhos.yml
└── docker-compose.yml

15 directories, 25 files
```


## Módulos
Adicionar *[submodule](/repos)* no projeto
- Instalação de Módulos
```bash
git submodule add git@github.com:amazoniacentral/docker-vps.git repos/docker-vps
```

- Remoção de Módulos
1. Remova a pasta do submódulo do índice do git
```bash
git rm -f scripts/docker-vps
```

2. Remova a pasta física do disco
```bash
rm -rf .git/modules/scripts/docker-vps
```

## Outras configurações
* **Banco de Dados:** [/database](/database/README.md)
* **Monitoramento:** [/netdata](/netdata/README.md)
* **Módulos:** [/repos](/repos)
---
**Desenvolvido por Francisco Silva (FSilva) — 2026**
