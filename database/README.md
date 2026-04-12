# Database PostgreSQL

Configuração inicial

[database/.env](.env.example)
```.env
POSTGRES_USER=admin_principal
POSTGRES_PASSWORD=sua_senha_segura
POSTGRES_DB=banco_principal 
```

Recomendado usar uma senha segura, gere uma senha segura rodando o seguinte comando.
```bash
openssl rand -base64 15
```

- Se você quiser isolar as aplicações com senhas diferentes:
Para que a nova aplicação tenha seu próprio usuário e sua própria senha, execute estes comandos dentro do container:
1. Acesse o console:
```bash
docker exec -it nome_do_container psql -U postgres
```
2. Crie o novo usuário e o novo banco:
```sql
-- Cria o usuário com a nova senha
CREATE USER usuario_app2 WITH PASSWORD 'senha_diferente_aqui';

-- Cria o banco de dados
CREATE DATABASE banco_app2;

-- Dá todas as permissões do novo banco para o novo usuário
GRANT ALL PRIVILEGES ON DATABASE banco_app2 TO usuario_app2;
```

Resumo
Se você não criar um usuário novo, usará o usuário padrão (POSTGRES_USER) e a senha padrão (POSTGRES_PASSWORD) definidos no seu arquivo Compose para acessar qualquer banco de dados que criar lá dentro. No PostgreSQL, a segurança é baseada em quem (usuário) acessa o quê (banco).

---
**Desenvolvido por Francisco Silva (FSilva) — 2026**
