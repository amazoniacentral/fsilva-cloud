<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./scripts
├── backup
│   ├── gdrive
│   │   ├── download-catalogo-bruto.sh
│   │   ├── download-treinamento.sh
│   │   └── envio-catalogo-compress.sh
│   └── r2
│       ├── backup-configs-encrypted.sh
│       ├── backup-db-encrypted.sh
│       ├── backup-volumes-encrypted.sh
│       ├── restore-configs-decrypted.sh
│       ├── restore-db-decrypted.sh
│       └── restore-volumes-decrypted.sh
├── database
│   ├── database.sh
│   ├── extensao_vetor.sh
│   ├── indicesn8n.sh
│   └── restaurar.sh
├── deploy
│   ├── dev_update.sh
│   ├── prod_update.sh
│   ├── README.md
│   └── setup.sh
├── documentacao
│   ├── blocos.sh
│   ├── cabecalho.sh
│   ├── estrutura.sh
│   ├── README.md
│   ├── rodape.sh
│   ├── setup.sh
│   └── variaveis.sh
├── git
│   ├── commit.sh
│   ├── setup.sh
│   ├── submodule_adicionar.sh
│   ├── submodule_branch.sh
│   ├── submodule_listar.sh
│   ├── submodule_remover.sh
│   └── tags.sh
├── alias.sh
├── clean.sh
├── containers.sh
├── copy.sh
├── crontab.sh
├── .env.example
├── haskey.sh
├── ia.sh
├── install.sh
├── ipv6.sh
├── limpar_traefik.sh
├── otimizar_rede.sh
├── README.md
├── reset.sh
├── setup_reclone.sh
└── status.sh

8 directories, 47 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações para baixar de outro servidor via Rsync
Execute o comando abaixo para baixar os arquivos
```bash 
bash db_baixar.sh
```
para evitar que peça todos os dados, crie um arquivo ``.env`` e preencha com os campos abaixo.
```.env <!-- ID: .env.example -->
# Configurações para o Rsync (Transferência Remota)
RSYNC_ORIGEM_USER=seu_usuario_remoto
RSYNC_ORIGEM_IP=123.123.123.123
RSYNC_ORIGEM_PATH=/caminho/no/servidor/remoto/backup.backup

# Configurações de Paths Locais (Opcional, conforme scripts anteriores)
DESTINO_PATH_BANCO=/caminho/local/do/backup.backup
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 22/11/2026_
<!-- END_ID:bloco_final -->
