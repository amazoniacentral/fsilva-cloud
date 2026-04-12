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

## Eatrutura do projeto 
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
│   │   ├── .gitignore
│   │   ├── LICENSE
│   │   ├── README.md
│   │   └── preparar_vps.sh
│   ├── gvendas
│   │   ├── assets
│   │   ├── public
│   │   ├── scripts
│   │   ├── src
│   │   ├── .env
│   │   ├── .gitignore
│   │   ├── README.md
│   │   ├── default.conf
│   │   ├── docker-compose.node.yml
│   │   ├── dump.rdb
│   │   ├── output.log
│   │   ├── package-lock.json
│   │   ├── package.json
│   │   └── teste.html
│   ├── push
│   │   ├── src
│   │   ├── .env.example
│   │   ├── .gitignore
│   │   ├── DockerFile
│   │   ├── LICENSE
│   │   ├── README-PUSH.md
│   │   ├── README-VAPID.md
│   │   ├── README-WHATSAPP.md
│   │   ├── README.md
│   │   ├── README.mdd
│   │   ├── docker-compose.node.yml
│   │   ├── package-lock.json
│   │   └── package.json
│   └── sgn
│       ├── assistente_ia
│       ├── conecta
│       ├── core
│       ├── docker
│       ├── feedback
│       ├── financas
│       ├── login_cli
│       ├── loja
│       ├── pagamento_online
│       ├── rede
│       ├── sgn
│       ├── templates
│       ├── utils
│       ├── .env.exemplo
│       ├── .gitignore
│       ├── DELETE
│       ├── Dockerfile
│       ├── README.md
│       ├── docker-compose.django.yml
│       ├── entrypoint.sh
│       ├── gestaovendasgooogleapi.json
│       ├── manage.py
│       ├── nginx.conf
│       ├── reqtermux.txt
│       └── requirements.in
├── scripts
│   ├── estrutura.sh
│   ├── estrutura_temp.txt
│   └── install.sh
├── .gitignore
├── .gitmodules
├── README.md
├── colocarnosfilhos.yml
└── docker-compose.yml

33 directories, 64 files
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
* **PostgreSQL:** [/database](/database/README.md)
* **Módulos:** [/repos](/repos)
---
**Desenvolvido por Francisco Silva (FSilva) — 2026**
