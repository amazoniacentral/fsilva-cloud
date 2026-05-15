<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

# Submodules

Adicionar *[submodule](./)* no projeto
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

## Estrutura do diretório
<!-- START_ID:bloco_estrutura -->
```bash
./repos
├── docker-vps
├── gvendas
├── push
├── sgn
└── README.md

5 directories, 1 file
```
<!-- END_ID:bloco_estrutura -->

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 14/05/2026_
<!-- END_ID:bloco_final -->
