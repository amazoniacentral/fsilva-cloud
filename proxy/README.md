# Proxy para acesso a web

[proxy/traefik/.env](traefik/.env.example)
```.env
# Gerar Certificado Let's
ACME_EMAIL=seu-email@dominio.com
#Painel do Traefik
DOMAIN=traefik.seu-dominio.com
```

[proxy/tunnel/.env](tunnel/.env.example)
```.env
# Configurações de Tunel
TUNNEL_TOKEN=seu_token_aqui_sem_aspas
```

Deixe somente o proxy que for usar
[proxy/docker-compose.proxy.yml](docker-compose.proxy.yml)
``` yml
include:
  - ./traefik/docker-compose.traefik.yml
  # - ./tunnel/docker-compose.tunnel.yml

```

---
**Desenvolvido por Francisco Silva (FSilva) — 2026**
