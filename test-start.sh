#!/bin/bash

# Script de teste para verificar se as correções funcionaram

echo "=== TESTE DO START.SH ==="
echo "Verificando estrutura de diretórios..."

# Verificar se diretórios existem
if [[ ! -d "atendechat" ]]; then
    echo "❌ Diretório 'atendechat' não encontrado!"
    exit 1
fi

if [[ ! -d "atendechat/backend" ]]; then
    echo "❌ Diretório 'atendechat/backend' não encontrado!"
    exit 1
fi

echo "✅ Estrutura de diretórios OK"

# Verificar se podemos navegar para os diretórios
echo "Testando navegação para atendechat/backend..."
cd atendechat/backend
if [[ $? -ne 0 ]]; then
    echo "❌ Falha ao navegar para atendechat/backend"
    exit 1
fi

echo "✅ Navegação OK"

# Verificar se docker-compose existe
if [[ -f "docker-compose.databases.yml" ]]; then
    echo "✅ docker-compose.databases.yml encontrado"
else
    echo "❌ docker-compose.databases.yml não encontrado"
fi

cd ../..
echo "✅ Teste concluído com sucesso!"
