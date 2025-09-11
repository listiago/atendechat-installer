#!/bin/bash

# Atendechat Test Script
# Versão: 1.1.0
# Descrição: Script para testar se a instalação foi bem-sucedida

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

# Função para testar conectividade
test_connectivity() {
    print_step "Testando conectividade..."

    # Testar internet
    if ping -c 1 google.com &> /dev/null; then
        print_success "Conectividade com internet: OK"
    else
        print_error "Sem conectividade com internet"
        return 1
    fi
}

# Função para testar dependências do sistema
test_system_dependencies() {
    print_step "Testando dependências do sistema..."

    local dependencies=("node" "npm" "docker" "docker-compose" "git")
    local missing=()

    for dep in "${dependencies[@]}"; do
        if command -v "$dep" &> /dev/null; then
            print_success "$dep: Instalado"
        else
            print_error "$dep: Não encontrado"
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Dependências faltando: ${missing[*]}"
        return 1
    fi
}

# Função para testar versões
test_versions() {
    print_step "Testando versões..."

    # Node.js
    local node_version=$(node --version | sed 's/v//')
    if [[ "${node_version%%.*}" -ge 20 ]]; then
        print_success "Node.js v$node_version: OK"
    else
        print_error "Node.js v$node_version: Requer v20+"
        return 1
    fi

    # Docker
    if docker --version &> /dev/null; then
        print_success "Docker: OK"
    else
        print_error "Docker: Não funcionando"
        return 1
    fi
}

# Função para testar containers Docker
test_docker_containers() {
    print_step "Testando containers Docker..."

    if [[ ! -d "backend" ]]; then
        print_error "Diretório backend não encontrado"
        return 1
    fi

    cd backend

    # Verificar se containers estão rodando
    if docker-compose -f docker-compose.databases.yml ps | grep -q "Up"; then
        print_success "Containers Docker: Rodando"

        # Testar conexão com banco
        if docker-compose -f docker-compose.databases.yml exec -T db_postgres pg_isready -U atendechat -d atendechat_db &> /dev/null; then
            print_success "Conexão com PostgreSQL: OK"
        else
            print_warning "Conexão com PostgreSQL: Falhou"
        fi

        # Testar conexão com Redis
        if docker-compose -f docker-compose.databases.yml exec -T cache redis-cli ping | grep -q "PONG"; then
            print_success "Conexão com Redis: OK"
        else
            print_warning "Conexão com Redis: Falhou"
        fi
    else
        print_error "Containers Docker: Não estão rodando"
        print_message "Execute: docker-compose -f backend/docker-compose.databases.yml up -d"
        return 1
    fi

    cd ..
}

# Função para testar aplicações
test_applications() {
    print_step "Testando aplicações..."

    # Ler configurações
    if [[ -f "backend/.env" ]]; then
        source backend/.env
        BACKEND_PORT="${PORT:-8080}"
        BACKEND_URL="${BACKEND_URL:-http://localhost}"
    else
        BACKEND_PORT="8080"
        BACKEND_URL="http://localhost"
    fi

    if [[ -f "frontend/.env" ]]; then
        source frontend/.env
        FRONTEND_PORT=$(echo "$REACT_APP_BACKEND_URL" | grep -oP '(?<=:)(\d+)')
        if [[ -z "$FRONTEND_PORT" ]]; then
            FRONTEND_PORT="3000"
        fi
    else
        FRONTEND_PORT="3000"
    fi

    # Testar backend
    if curl -s --max-time 10 "${BACKEND_URL}:${BACKEND_PORT}" > /dev/null 2>&1; then
        print_success "Backend (${BACKEND_URL}:${BACKEND_PORT}): OK"
    else
        print_error "Backend (${BACKEND_URL}:${BACKEND_PORT}): Não respondendo"
        return 1
    fi

    # Testar frontend
    if curl -s --max-time 10 "http://localhost:${FRONTEND_PORT}" > /dev/null 2>&1; then
        print_success "Frontend (http://localhost:${FRONTEND_PORT}): OK"
    else
        print_error "Frontend (http://localhost:${FRONTEND_PORT}): Não respondendo"
        return 1
    fi
}

# Função para mostrar relatório final
show_report() {
    print_message ""
    print_message "=== RELATÓRIO DE TESTE ==="

    if [[ $TESTS_PASSED -eq $TOTAL_TESTS ]]; then
        print_success "✅ Todos os testes passaram! ($TESTS_PASSED/$TOTAL_TESTS)"
        print_message ""
        print_message "🎉 Instalação bem-sucedida!"
        print_message "Acesse o Atendechat em:"
        print_message "  Frontend: http://localhost:3000"
        print_message "  Backend: http://localhost:8080"
    else
        print_error "❌ Alguns testes falharam ($TESTS_PASSED/$TOTAL_TESTS)"
        print_message ""
        print_message "Verifique os erros acima e tente:"
        print_message "  1. ./restart.sh"
        print_message "  2. Verificar logs: docker-compose -f backend/docker-compose.databases.yml logs"
        print_message "  3. Verificar processos: ps aux | grep node"
    fi
}

# Função principal
main() {
    print_message "=== ATENDECHAT TEST SCRIPT ==="
    print_message "Testando instalação..."
    print_message ""

    TESTS_PASSED=0
    TOTAL_TESTS=0

    # Array de testes
    local tests=(
        "test_connectivity"
        "test_system_dependencies"
        "test_versions"
        "test_docker_containers"
        "test_applications"
    )

    # Executar testes
    for test_func in "${tests[@]}"; do
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if $test_func; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
        fi
        echo
    done

    # Mostrar relatório
    show_report
}

# Executar função principal
main "$@"
