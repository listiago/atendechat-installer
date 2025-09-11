#!/bin/bash

# Atendechat Stop Script
# Versão: 1.0.0
# Descrição: Script para parar aplicações do Atendechat

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

# Função para parar aplicações Node.js
stop_applications() {
    print_step "Parando aplicações Node.js..."

    # Parar processos do backend
    if pkill -f 'node.*server.ts' 2>/dev/null; then
        print_message "Backend parado"
    else
        print_warning "Nenhum processo de backend encontrado"
    fi

    # Parar processos do frontend
    if pkill -f 'react-scripts start' 2>/dev/null; then
        print_message "Frontend parado"
    else
        print_warning "Nenhum processo de frontend encontrado"
    fi

    # Aguardar processos terminarem
    sleep 2

    print_message "Aplicações Node.js paradas"
}

# Função para parar containers Docker
stop_docker_containers() {
    print_step "Parando containers Docker..."

    if [[ -d "backend" ]]; then
        cd backend

        if [[ -f "docker-compose.databases.yml" ]]; then
            docker-compose -f docker-compose.databases.yml down 2>/dev/null || print_warning "Falha ao parar containers"
            print_message "Containers Docker parados"
        else
            print_warning "Arquivo docker-compose.databases.yml não encontrado"
        fi

        cd ..
    else
        print_warning "Diretório backend não encontrado"
    fi
}

# Função para verificar se tudo foi parado
check_status() {
    print_step "Verificando status..."

    # Verificar processos Node.js
    if ps aux | grep -E '(node|npm)' | grep -v grep > /dev/null; then
        print_warning "Ainda há processos Node.js rodando:"
        ps aux | grep -E '(node|npm)' | grep -v grep
    else
        print_message "✅ Nenhum processo Node.js rodando"
    fi

    # Verificar containers Docker
    if docker ps | grep -E '(db_postgres|cache)' > /dev/null; then
        print_warning "Ainda há containers Docker rodando:"
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E '(db_postgres|cache)'
    else
        print_message "✅ Nenhum container Docker rodando"
    fi
}

# Função para limpeza opcional
cleanup() {
    read -p "Deseja fazer limpeza dos containers Docker? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Fazendo limpeza dos containers..."

        # Parar e remover containers
        docker-compose -f backend/docker-compose.databases.yml down -v 2>/dev/null || true

        # Remover imagens não utilizadas
        docker image prune -f

        print_message "Limpeza concluída"
    fi
}

# Função principal
main() {
    print_message "=== ATENDECHAT STOP SCRIPT ==="
    print_message "Parando aplicações..."
    print_message ""

    # Verificar se estamos no diretório correto
    if [[ ! -d "backend" && ! -d "frontend" ]]; then
        print_error "Diretórios backend/ e frontend/ não encontrados"
        print_message "Execute este script dentro do diretório atendechat/"
        exit 1
    fi

    # Parar aplicações
    stop_applications

    # Parar containers Docker
    stop_docker_containers

    # Verificar status
    check_status

    # Limpeza opcional
    cleanup

    print_message ""
    print_message "=== STOP CONCLUÍDO ==="
    print_message "Todas as aplicações foram paradas!"
    print_message ""
    print_message "Para reiniciar: ./restart.sh"
    print_message "Para instalar novamente: ./install.sh"
}

# Executar função principal
main "$@"
