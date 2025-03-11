#!/bin/bash

CONFIGS=(a-colocated b-distributed c-pp-details_ratings-reviews d-pp-ratings_details-reviews e-pp-reviews_details-ratings f-pp_ratings-details-reviews g-details_pp-ratings-reviews h-ratings_pp-details-reviews i-reviews_pp-details-ratings j-pp-details_ratings_reviews k-pp-ratings_details_reviews l-pp-reviews_details_ratings m-details-ratings_pp_reviews n-details-reviews_pp_ratings o-ratings-reviews_pp_details)
VIRTUAL_USERS=(200 300 400 500)
CONFIG_PATH=~/bookinfo-serviceweaver/100products

# Função para aguardar o endpoint estar disponível
wait_for_service() {
    local endpoint=$1
    echo "Aguardando o serviço estar disponível: $endpoint"
    until curl -s -o /dev/null -w "%{http_code}" "$endpoint" | grep -q "200"; do
        sleep 5
    done
    echo "Serviço disponível: $endpoint"
}

# Loop sobre cada configuração
for config in "${CONFIGS[@]}"; do
    echo "Aplicando configuração: $config"
    kubectl apply -f "$CONFIG_PATH/$config.yaml"
    sleep 10
    
    ENDPOINT=$(kubectl get services -o json | jq -r '.items[] | select(.metadata.name | startswith("productpage-")) | .spec.clusterIP')
    
    if [ -z "$ENDPOINT" ] || [ "$ENDPOINT" == "null" ]; then
        echo "Erro: Nenhum endpoint encontrado."
        exit 1
    fi
    
    FULL_URL="http://$ENDPOINT"
    wait_for_service "$FULL_URL"
    
    # Loop sobre cada quantidade de usuários virtuais
    for users in "${VIRTUAL_USERS[@]}"; do
        TIMESTAMP=$(date +"%Y%m%d%H%M%S")
        OUTPUT_VALUE="${config}_${users}_${TIMESTAMP}"
    
        echo "Rodando teste com $users usuários virtuais para $config"
        k6 run --env VUS=$users --env OUTPUT="$OUTPUT_VALUE" --env HOST="$ENDPOINT" shared-iterations-test.js
        sleep 20
    done

    kubectl delete -f "$CONFIG_PATH/$config.yaml"
    sleep 20

done

echo "Testes finalizados."
