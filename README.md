# fsilva-cloud
Stack central de orquestração e infraestrutura para o ecossistema FSilva. Gerencia o projeto GVendas e serviços de terceiros via Docker Compose e Git Submodules.

## 🚀 Instalação Rápida na VPS

Para preparar a máquina do zero (Docker v27, Rede Traefik, Firewall UFW, ZRAM, SWAP e Git), execute o script de provisionamento:

```bash
apt update && apt install -y curl && curl -sSL [https://raw.githubusercontent.com/amazoniacentral/docker-vps/main/preparar_vps.sh](https://raw.githubusercontent.com/amazoniacentral/docker-vps/main/preparar_vps.sh) | sudo bash
```
## 🔐 Autenticação no GitHub
​O script acima gera uma chave SSH para que a VPS possa baixar seus repositórios privados e submódulos sem pedir senha.
1.​Copie a chave pública gerada:
```bash
cat ~/.ssh/id_ed25519.pub
```

2. Adicione esta chave no seu GitHub em: **Settings -> Deploy Keys** (no repositório) ou em **Settings -> SSH and GPG keys** (na sua conta).

​## 🏗️ Instalação da Estrutura FSilva Cloud
​Após configurar a chave no GitHub, execute o instalador da stack para clonar os repositórios e subir os containers:

```bash
apt update && apt install -y curl && curl -sSL [https://raw.githubusercontent.com/amazoniacentral/fsilva-cloud/main/scripts/install.sh](https://raw.githubusercontent.com/amazoniacentral/fsilva-cloud/main/scripts/install.sh) | sudo bash
```

---
**Desenvolvido por Francisco Silva (FSilva) — 2026**
