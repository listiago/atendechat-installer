#!/bin/bash

# AtendeChat - Script de Inicialização Manual
# Versão: 1.0.0
# Descrição: Inicia aplicações manualmente verificando conflitos

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

# Função para verificar processos existentes
check_and_clean() {
    print_step "Verificando processos existentes..."

    # Verificar processos Node.js rodando
    local node_processes=$(ps aux | grep -E "(node|npm)" | grep -v grep | wc -l)
    local backend_port=$(netstat -tlnp 2>/dev/null | grep :8080 | wc -l)
    local frontend_port=$(netstat -tlnp 2>/dev/null | grep :3000 | wc -l)

    if [[ $node_processes -gt 0 ]] || [[ $backend_port -gt 0 ]] || [[ $frontend_port -gt 0 ]]; then
        print_warning "⚠️  Detectados processos/aplicações já rodando!"
        print_message "📊 Processos Node.js: $node_processes"
        print_message "🔌 Porta 8080 (Backend): $backend_port"
        print_message "🔌 Porta 3000 (Frontend): $frontend_port"

        # Listar processos específicos
        print_message "📋 Processos encontrados:"
        ps aux | grep -E "(node|npm)" | grep -v grep | head -5

        print_message ""
        print_message "🔧 OPÇÕES:"
        print_message "  1. Parar processos existentes e iniciar novos"
        print_message "  2. Usar aplicações já rodando (não fazer nada)"
        print_message "  3. Apenas verificar status"

        read -p "Escolha uma opção (1/2/3) [3]: " choice
        choice=${choice:-3}

        case $choice in
            1)
                print_message "Parando processos existentes..."
                pkill -f "node.*dist/server.js" 2>/dev/null || true
                pkill -f "npm.*start" 2>/dev/null || true
                sleep 3
                return 0  # OK para iniciar novos
                ;;
            2)
                print_success "✅ Usando aplicações já em execução"
                print_message "📊 Aplicações já estão rodando!"
                exit 0
                ;;
            *)
                print_message "Apenas verificando status..."
                return 1  # Não iniciar novos
                ;;
        esac
    else
        print_success "✅ Nenhum processo conflitante encontrado"
        return 0
    fi
}

# Função para iniciar backend
start_backend() {
    print_step "Iniciando Backend..."

    if [[ ! -d "atendechat/backend" ]]; then
        print_error "Diretório backend não encontrado!"
        exit 1
    fi

    cd atendechat/backend

    # Verificar se já está rodando
    if netstat -tlnp 2>/dev/null | grep -q :8080; then
        print_warning "⚠️  Backend já está rodando na porta 8080"
        return 0
    fi

    print_message "Executando: npm start"
    npm start &
    BACKEND_PID=$!

    print_success "✅ Backend iniciado (PID: $BACKEND_PID)"
    cd ../..
}

# Função para iniciar frontend
start_frontend() {
    print_step "Iniciando Frontend..."

    if [[ ! -d "atendechat/frontend" ]]; then
        print_error "Diretório frontend não encontrado!"
        exit 1
    fi

    cd atendechat/frontend

    # Verificar se já está rodando
    if netstat -tlnp 2>/dev/null | grep -q :3000; then
        print_warning "⚠️  Frontend já está rodando na porta 3000"
        return 0
    fi

    print_message "Executando: npm start"
    NODE_OPTIONS="--openssl-legacy-provider" npm start &
    FRONTEND_PID=$!

    print_success "✅ Frontend iniciado (PID: $FRONTEND_PID)"
    cd ../..
}

# Função principal
main() {
    print_message "=== ATENDECHAT - INICIALIZAÇÃO MANUAL ==="
    print_message "Iniciando aplicações manualmente com verificação de conflitos"
    print_message ""

    # Verificar e limpar processos
    check_and_clean
    if [[ $? -eq 1 ]]; then
        print_message "Verificação concluída. Saindo..."
        exit 0
    fi

    # Iniciar aplicações
    start_backend
    sleep 2
    start_frontend

    print_message ""
    print_success "🎉 APLICAÇÕES INICIADAS COM SUCESSO!"
    print_message ""
    print_message "Acesso:"
    print_message "  Frontend: http://localhost:3000"
    print_message "  Backend:  http://localhost:8080"
    print_message ""
    print_message "Para parar: ./stop.sh"
    print_message "Para verificar: ps aux | grep -E '(node|npm)' | grep -v grep"
}

# Executar função principal
main "$@"
