#!/bin/bash

# AtendeChat - Script de Status do Sistema
# Versão: 1.0.0
# Descrição: Verifica o status completo do sistema

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

# Função para verificar Docker
check_docker() {
    print_step "Verificando Docker..."

    if docker info >/dev/null 2>&1; then
        print_success "✅ Docker está rodando"
        return 0
    else
        print_error "❌ Docker não está rodando"
        return 1
    fi
}

# Função para verificar containers
check_containers() {
    print_step "Verificando containers Docker..."

    local postgres_status="❌"
    local redis_status="❌"

    # Verificar PostgreSQL
    if docker exec backend_db_postgres_1 pg_isready -U atendechat -d atendechat_db 2>/dev/null; then
        postgres_status="✅"
    fi

    # Verificar Redis
    if docker exec backend_cache_1 redis-cli ping 2>/dev/null | grep -q "PONG"; then
        redis_status="✅"
    fi

    echo "PostgreSQL: $postgres_status"
    echo "Redis: $redis_status"

    if [[ $postgres_status == "✅" && $redis_status == "✅" ]]; then
        print_success "Containers funcionando corretamente"
        return 0
    else
        print_warning "Alguns containers com problemas"
        return 1
    fi
}

# Função para verificar processos Node.js
check_node_processes() {
    print_step "Verificando processos Node.js..."

    local backend_status="❌"
    local frontend_status="❌"

    # Verificar backend
    if ps aux | grep -v grep | grep -q "ts-node-dev"; then
        backend_status="✅"
    fi

    # Verificar frontend
    if ps aux | grep -v grep | grep -q "react-scripts"; then
        frontend_status="✅"
    fi

    echo "Backend: $backend_status"
    echo "Frontend: $frontend_status"

    if [[ $backend_status == "✅" && $frontend_status == "✅" ]]; then
        print_success "Processos Node.js funcionando"
        return 0
    else
        print_warning "Alguns processos com problemas"
        return 1
    fi
}

# Função para verificar conectividade das aplicações
check_applications() {
    print_step "Verificando conectividade das aplicações..."

    local backend_status="❌"
    local frontend_status="❌"

    # Verificar backend
    if curl -s --max-time 5 http://localhost:8080 > /dev/null 2>&1; then
        backend_status="✅"
    fi

    # Verificar frontend
    if curl -s --max-time 5 http://localhost:3000 > /dev/null 2>&1; then
        frontend_status="✅"
    fi

    echo "Backend (porta 8080): $backend_status"
    echo "Frontend (porta 3000): $frontend_status"

    if [[ $backend_status == "✅" && $frontend_status == "✅" ]]; then
        print_success "Aplicações respondendo corretamente"
        return 0
    else
        print_warning "Algumas aplicações não respondendo"
        return 1
    fi
}

# Função para verificar banco de dados
check_database() {
    print_step "Verificando banco de dados..."

    cd atendechat/backend

    # Verificar conexão com banco
    if npm run db:check 2>/dev/null; then
        print_success "✅ Conexão com banco de dados OK"
        cd ../..
        return 0
    else
        print_error "❌ Problemas com banco de dados"
        cd ../..
        return 1
    fi
}

# Função para mostrar informações detalhadas
show_detailed_info() {
    echo ""
    print_step "Informações detalhadas:"

    echo "=== Containers Docker ==="
    docker ps --filter "name=atendechat" --filter "name=backend_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "Nenhum container encontrado"

    echo ""
    echo "=== Processos Node.js ==="
    ps aux | grep -E "(ts-node-dev|react-scripts)" | grep -v grep | awk '{print $2, $11, $12}' || echo "Nenhum processo Node.js encontrado"

    echo ""
    echo "=== Uso de portas ==="
    echo "Porta 3000 (Frontend):"
    lsof -i :3000 2>/dev/null | head -2 || echo "Porta 3000 livre"

    echo "Porta 8080 (Backend):"
    lsof -i :8080 2>/dev/null | head -2 || echo "Porta 8080 livre"

    echo "Porta 5432 (PostgreSQL):"
    lsof -i :5432 2>/dev/null | head -2 || echo "Porta 5432 livre"

    echo "Porta 6379 (Redis):"
    lsof -i :6379 2>/dev/null | head -2 || echo "Porta 6379 livre"
}

# Função para dar recomendações
give_recommendations() {
    local issues=0

    # Verificar se há problemas
    if ! check_docker 2>/dev/null; then ((issues++)); fi
    if ! check_containers 2>/dev/null; then ((issues++)); fi
    if ! check_node_processes 2>/dev/null; then ((issues++)); fi
    if ! check_applications 2>/dev/null; then ((issues++)); fi

    if [[ $issues -gt 0 ]]; then
        echo ""
        print_warning "Recomendações para corrigir problemas:"

        if ! check_docker 2>/dev/null; then
            echo "• Inicie o Docker Desktop"
        fi

        if ! check_containers 2>/dev/null; then
            echo "• Execute: ./start.sh (para iniciar containers)"
        fi

        if ! check_node_processes 2>/dev/null; then
            echo "• Execute: ./start.sh (para iniciar aplicações)"
        fi

        if ! check_applications 2>/dev/null; then
            echo "• Aguarde mais alguns segundos para aplicações iniciarem"
            echo "• Verifique logs: tail -f logs do backend/frontend"
        fi

        echo ""
        print_message "Para iniciar tudo automaticamente: ./start.sh"
    fi
}

# Função principal
main() {
    print_message "=== ATENDECHAT - STATUS DO SISTEMA ==="
    print_message "Verificando status completo..."
    print_message ""

    local overall_status=0

    # Verificações básicas
    check_docker || overall_status=1
    check_containers || overall_status=1
    check_node_processes || overall_status=1
    check_applications || overall_status=1
    check_database || overall_status=1

    # Informações detalhadas
    show_detailed_info

    # Recomendações
    give_recommendations

    echo ""
    if [[ $overall_status -eq 0 ]]; then
        print_success "🎉 SISTEMA TOTALMENTE OPERACIONAL!"
        print_message "AtendeChat está funcionando perfeitamente!"
        echo ""
        print_message "Acesso:"
        print_message "  Frontend: http://localhost:3000"
        print_message "  Backend:  http://localhost:8080"
    else
        print_warning "⚠️  SISTEMA COM ALGUNS PROBLEMAS"
        print_message "Verifique as recomendações acima para corrigir."
        echo ""
        print_message "Para iniciar tudo: ./start.sh"
        print_message "Para parar tudo: ./stop.sh"
    fi
}

# Executar função principal
main "$@"
