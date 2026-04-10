#!/bin/bash

echo "=== Monitor de Saúde de Aplicação ==="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

BASE_URL="http://localhost:8080"

# 1. Health check
echo "1. Verificando saúde da aplicação..."
HEALTH=$(curl -s $BASE_URL/health)

if [ -z "$HEALTH" ]; then
    echo -e "${RED}X Aplicação não respondeu${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Aplicação está saudável${NC}"
echo "$HEALTH" | python3 -m json.tool

# 2. Métricas
echo ""
echo "2. Métricas da aplicação..."
METRICS=$(curl -s $BASE_URL/metrics)

if [ -z "$METRICS" ]; then
    echo -e "${RED}X Endpoint /metrics retornou vazio${NC}"
    exit 1
fi

echo "$METRICS" | python3 -m json.tool

# 3. Taxa de sucesso
echo ""
echo "3. Verificando taxa de sucesso..."

SUCCESS_RATE=$(echo "$METRICS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('success_rate_percent', 0))
")

# Valida se é número
if ! [[ "$SUCCESS_RATE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo -e "${RED}X Taxa inválida: $SUCCESS_RATE${NC}"
    exit 1
fi

if (( $(echo "$SUCCESS_RATE >= 95.0" | bc -l) )); then
    echo -e "${GREEN}✓ Taxa de sucesso: $SUCCESS_RATE% (OK)${NC}"
else
    echo -e "${RED}X Taxa de sucesso: $SUCCESS_RATE% (BAIXA)${NC}"
fi