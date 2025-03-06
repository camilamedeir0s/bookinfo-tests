#!/bin/bash

# Verifica se o nome do arquivo OUTPUT foi passado
if [ -z "$1" ]; then
  echo "Uso: $0 <nome_base_output>"
  exit 1
fi

OUTPUT_BASE="$1"

# Array com os valores de VUS
VUS_VALUES=(100 150 200)

# Itera sobre os valores de VUS e executa o k6
for VUS in "${VUS_VALUES[@]}"; do
  OUTPUT_FILE="${OUTPUT_BASE}_${VUS}.json"
  echo "Executando teste com VUS=${VUS} e OUTPUT=${OUTPUT_FILE}..."
  k6 run --env VUS=$VUS --env OUTPUT="$OUTPUT_FILE" script_10iterations_env.js
done

echo "Todos os testes foram concluídos."
