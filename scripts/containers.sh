#!/bin/bash
set -e

# INTERAÇÃO PARA ESCOLHER CONTAINER E AÇÃO
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Deseja gerenciar algum container?" >&3
echo -e "1) Sim" >&3
echo -e "2) Sair" >&3
read -u 3 -rp "Opção (1 ou 2): " OPCAO_MENU

if [ "$OPCAO_MENU" == "1" ]; then
    # Obtém a lista de nomes dos containers ativos
    mapfile -t CONTAINERS < <(docker ps --format "{{.Names}}")
    
    if [ ${#CONTAINERS[@]} -eq 0 ]; then
        echo -e "Nenhum container em execução." >&3
    else
        echo -e "\nSelecione o Container:" >&3
        for i in "${!CONTAINERS[@]}"; do
            echo -e "$((i+1))) ${CONTAINERS[$i]}" >&3
        done
        read -u 3 -rp "Número do container: " NUM_ESCOLHIDO

        if [[ "$NUM_ESCOLHIDO" =~ ^[0-9]+$ ]] && [ "$NUM_ESCOLHIDO" -ge 1 ] && [ "$NUM_ESCOLHIDO" -le "${#CONTAINERS[@]}" ]; then
            CONTAINER_NOME="${CONTAINERS[$((NUM_ESCOLHIDO-1))]}"
            
            echo -e "\nO que deseja fazer com [$CONTAINER_NOME]?" >&3
            echo -e "1) Ver Logs (Tempo Real)" >&3
            echo -e "2) Entrar no Terminal (Bash/Sh)" >&3
            echo -e "3) Ver Volumes Conectados" >&3
            echo -e "4) Ver Status Detalhado (Inspect)" >&3
            echo -e "5) Ver Estatísticas (CPU/RAM)" >&3
            read -u 3 -rp "Ação: " ACAO

            case $ACAO in
                1)
                    echo -e "Pressione Ctrl+C para sair dos logs..." >&3
                    docker logs -f --tail 100 "$CONTAINER_NOME"
                    ;;
                2)
                    echo -e "Acessando terminal..." >&3
                    docker exec -it "$CONTAINER_NOME" /bin/bash || docker exec -it "$CONTAINER_NOME" /bin/sh
                    ;;
                3)
                    echo -e "\nVolumes e Montagens:" >&3
                    docker inspect -f '{{ range .Mounts }}{{ .Type }}: {{ .Source }} -> {{ .Destination }}{{ "\n" }}{{ end }}' "$CONTAINER_NOME"
                    ;;
                4)
                    docker inspect "$CONTAINER_NOME" | grep -E "Status|CreatedAt|IPAddress"
                    ;;
                5)
                    docker stats --no-stream "$CONTAINER_NOME"
                    ;;
                *)
                    echo -e "Ação inválida." >&3
                    ;;
            esac
        else
            echo -e "Container inválido." >&3
        fi
    fi
fi
exec 3>&-