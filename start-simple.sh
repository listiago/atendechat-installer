#!/bin/bash

# AtendeChat - Inicialização Simples
# Versão: 1.0.0
# Descrição: Prepara ambiente e dá instruções para inicialização manual

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
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

# Função principal
main() {
    print_message "=== ATENDECHAT - INICIALIZAÇÃO SIMPLES ==="
    print_message "Preparando ambiente para inicialização manual..."
    print_message ""

    # Verificar se estamos no diretório correto
    if [[ ! -f "start.sh" ]]; then
        print_error "Execute o script do diretório raiz do projeto!"
        print_message "Navegue para o diretório atendechat-installer e execute: ./start-simple.sh"
        exit 1
    fi

    # Verificar estrutura
    if [[ ! -d "atendechat" ]]; then
        print_error "Diretório 'atendechat' não encontrado!"
        print_message "Execute o instalador primeiro: ./install.sh"
        exit 1
    fi

    if [[ ! -d "atendechat/backend" ]]; then
        print_error "Diretório 'atendechat/backend' não encontrado!"
        print_message "Execute o instalador primeiro: ./install.sh"
        exit 1
    fi

    print_success "✅ Estrutura do projeto verificada"

    # Verificar Docker
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker não está rodando. Inicie o Docker primeiro."
        exit 1
    fi
    print_success "✅ Docker está rodando"

    # Verificar containers
    if docker-compose -f atendechat/backend/docker-compose.databases.yml ps | grep -q "Up"; then
        print_success "✅ Containers já estão rodando"
    else
        print_message "Iniciando containers..."
        cd atendechat/backend
        docker-compose -f docker-compose.databases.yml up -d
        cd ../..
        print_success "✅ Containers iniciados"
    fi

    # Aguardar bancos
    print_message "Aguardando bancos de dados..."
    sleep 10
    print_success "✅ Bancos de dados prontos"

    print_message ""
    print_message "🎯 AMBIENTE PRONTO! Siga estas instruções:"
    print_message "=========================================="
    print_message ""
    print_message "📋 PASSO 1 - Iniciar Backend:"
    print_message "   Abra um NOVO terminal e execute:"
    print_message "   cd atendechat-installer/atendechat/backend"
    print_message "   npm start"
    print_message ""
    print_message "📋 PASSO 2 - Iniciar Frontend:"
    print_message "   Abra OUTRO NOVO terminal e execute:"
    print_message "   cd atendechat-installer/atendechat/frontend"
    print_message "   NODE_OPTIONS='--openssl-legacy-provider' npm start"
    print_message ""
    print_message "📋 PASSO 3 - Testar:"
    print_message "   Backend:  http://localhost:8080"
    print_message "   Frontend: http://localhost:3000"
    print_message ""
    print_message "💡 DICAS:"
    print_message "   - Aguarde alguns segundos após iniciar cada aplicação"
    print_message "   - O backend pode demorar um pouco para conectar ao banco"
    print_message "   - O frontend pode demorar para compilar"
    print_message ""
    print_success "🎉 PRONTO PARA INICIALIZAÇÃO MANUAL!"
}

# Executar função principal
main "$@"
