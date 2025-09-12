#!/bin/bash

# Script para criar usuário administrador manualmente
# Versão: 1.0.0

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Verificar se estamos no diretório correto
if [[ ! -d "atendechat" ]]; then
    print_error "Diretório 'atendechat' não encontrado!"
    print_message "Execute este script do diretório do instalador"
    exit 1
fi

# Verificar se containers estão rodando
if ! docker ps | grep -q "atendechat_db_postgres_1"; then
    print_error "Container PostgreSQL não está rodando!"
    print_message "Execute: ./start.sh"
    exit 1
fi

print_step "Criando usuário administrador..."

# Coletar informações
read -p "Email do administrador: " USER_EMAIL
read -s -p "Senha do administrador: " USER_PASSWORD
echo

cd atendechat/backend

# Verificar se o usuário já existe
USER_EXISTS=$(docker exec atendechat_db_postgres_1 psql -U atendechat -d atendechat_db -t -c "SELECT COUNT(*) FROM \"Users\" WHERE email = '$USER_EMAIL';" 2>/dev/null || echo "0")

if [[ "$USER_EXISTS" -gt 0 ]]; then
    print_success "Usuário administrador já existe!"
    print_message "Email: $USER_EMAIL"
else
    # Criar hash da senha
    PASSWORD_HASH=$(node -e "
    const bcrypt = require('bcryptjs');
    const salt = bcrypt.genSaltSync(10);
    const hash = bcrypt.hashSync('$USER_PASSWORD', salt);
    console.log(hash);
    " 2>/dev/null)

    if [[ -n "$PASSWORD_HASH" ]]; then
        # Inserir usuário no banco
        docker exec atendechat_db_postgres_1 psql -U atendechat -d atendechat_db -c "
        INSERT INTO \"Users\" (email, password, name, profile, \"createdAt\", \"updatedAt\")
        VALUES ('$USER_EMAIL', '$PASSWORD_HASH', 'Administrador', 'admin', NOW(), NOW());
        " 2>/dev/null

        if [[ $? -eq 0 ]]; then
            print_success "✅ Usuário administrador criado com sucesso!"
            print_message "Email: $USER_EMAIL"
            print_message "Senha: $USER_PASSWORD"
        else
            print_error "❌ Falha ao criar usuário no banco"
        fi
    else
        print_error "❌ Falha ao gerar hash da senha"
    fi
fi

cd ../..

print_message ""
print_message "Para testar o login:"
print_message "  Frontend: http://localhost:3000"
print_message "  Email: $USER_EMAIL"
print_message "  Senha: $USER_PASSWORD"
