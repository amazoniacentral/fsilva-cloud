# fsilva-cloud
Stack central de orquestração e infraestrutura para o ecossistema FSilva. Gerencia o projeto GVendas e serviços de terceiros via Docker Compose e Git Submodules.

## 🚀 Instalação Rápida na VPS
* **Repositório:** [amazoniacentral/docker-vps](https://github.com/amazoniacentral/docker-vps)
* **Script de Instalação:** [preparar_vps.sh](https://raw.githubusercontent.com/amazoniacentral/docker-vps/main/preparar_vps.sh)

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

1. Remover projeto
- Remova a pasta do submódulo do índice do git
```bash
git rm -f scripts/docker-vps
```

- Remova a pasta física do disco
```bash
rm -rf .git/modules/scripts/docker-vps
```
2. Adicionar projeto
```bash
git submodule add git@github.com:amazoniacentral/docker-vps.git repos/docker-vps
```
# Outras configurações
* **PostgresSql:** [/database](/database/README.md)
* **Módulos:** [/repos](/repos)
---
**Desenvolvido por Francisco Silva (FSilva) — 2026**
