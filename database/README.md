<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

# Database PostgreSQL

Configuração inicial

### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
#Credenciais Administrativas do Banco de Dados

POSTGRES_USER=postgres
#POSTGRES_PASSWORD=sua_senha_segura
POSTGRES_DB=postgres 
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

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 15/05/2026_
<!-- END_ID:bloco_final -->
