<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./apps/videos
├── docker-compose.yml
├── .env
├── .env.example
└── README.md

1 directory, 4 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# --- NextAuth / Auth.js (v5) ---

# Chave secreta para criptografia de sessões
AUTH_SECRET=sua_chave_secreta_bem_longa_e_aleatoria_aqui

# Chave secreta para o NextAuth
NEXTAUTH_SECRET=sua_chave_secreta_bem_longa_e_aleatoria_aqui

# URL oficial de autenticação
AUTH_URL=https://seu-dominio-de-producao.com.br

# URL oficial do NextAuth
NEXTAUTH_URL=https://seu-dominio-de-producao.com.br

# Permite confiar no host do proxy reverso
AUTH_TRUST_HOST=true


# --- Credenciais do Django (OAuth2 / OpenID Connect) ---

# Client ID da aplicação no Django
DJANGO_CLIENT_ID=seu_client_id_do_django

# Client Secret da aplicação no Django
DJANGO_CLIENT_SECRET=seu_client_secret_do_django

# URL do provedor Django OIDC / Issuer
DJANGO_ISSUER=https://suacentral.com.br


# --- Variáveis Públicas (Injetadas no build do Next.js) ---

# URL da API pública para o frontend
NEXT_PUBLIC_API_URL=https://sua-api.com.br

# URL do site público para o frontend
NEXT_PUBLIC_SITE_URL=https://seu-dominio-de-producao.com.br


# --- Cloudflare R2 & Armazenamento Híbrido ---

# ID da conta
R2_ACCOUNT_ID=c80db91fb45bfaec507af2db8b5c1f

# Valor do token
R2_TOKEN=cfat_a8qtJe9qj7kTrFJCK7WQgCBUAfCv3g4oXI

# ID da chave de acesso
R2_ACCESS_KEY_ID=1bee7aa7865ca77689682cfd23ee1ba9

# Chave de acesso secreta
R2_SECRET_ACCESS_KEY=e4a8d9264e7922613f7c11b2981027b6e48c114f1

# Nome do bucket
R2_BUCKET_NAME=videos

# URL pública do bucket
R2_PUBLIC_URL=https://pub-seu-subdominio.r2.dev

# Tipo de armazenamento local/r2
DEFAULT_STORAGE=r2

# --- Ambiente e Proxy ---
VIDEOS_NODE_ENV=production
VIDEOS_AUTH_TRUST_HOST=true
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 23/11/2026_
<!-- END_ID:bloco_final -->
