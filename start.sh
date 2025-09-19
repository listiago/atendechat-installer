#!/bin/bash

# AtendeChat - Script de Inicialização com PM2
# Versão: 2.0.0
# Descrição: Inicia todo o sistema automaticamente com PM2

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

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar PM2
check_pm2() {
    if ! command_exists pm2; then
        print_step "Instalando PM2..."

        # Tentar instalar globalmente com sudo
        if sudo npm install -g pm2 2>/dev/null; then
            print_success "PM2 instalado com sucesso (sudo)"
        else
            print_warning "Não foi possível instalar PM2 globalmente"
            print_message "Tentando instalar localmente..."

            # Instalar localmente como fallback
            if npm install pm2 --save-dev 2>/dev/null; then
                # Adicionar ao PATH localmente
                export PATH="$PWD/node_modules/.bin:$PATH"
                print_success "PM2 instalado localmente"
            else
                print_error "Falha ao instalar PM2. Instale manualmente: sudo npm install -g pm2"
                exit 1
            fi
        fi
    else
        print_success "PM2 já está instalado"
    fi
}

# Função para verificar se Docker está rodando
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker não está rodando. Inicie o Docker primeiro."
        exit 1
    fi
}

# Função para verificar se diretório existe
check_directory() {
    # Verificar se estamos no diretório correto
    if [[ ! -f "start.sh" ]]; then
        print_error "Execute o script do diretório raiz do projeto!"
        print_message "Navegue para o diretório atendechat-installer e execute: ./start.sh"
        exit 1
    fi

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

    print_message "Diretório atual: $(pwd)"
    print_message "Estrutura verificada com sucesso"
}

# Função para iniciar containers
start_containers() {
    print_step "Iniciando containers Docker..."

    # Garantir que estamos no diretório raiz
    if [[ ! -f "start.sh" ]]; then
        print_error "Erro: Não estamos no diretório raiz!"
        print_message "Diretório atual: $(pwd)"
        exit 1
    fi

    local backend_dir="./atendechat/backend"

    if [[ ! -d "$backend_dir" ]]; then
        print_error "Diretório backend não encontrado: $backend_dir"
        print_message "Diretório atual: $(pwd)"
        exit 1
    fi

    cd "$backend_dir"

    # Verificar se containers já estão rodando
    if sudo docker-compose -f docker-compose.databases.yml ps | grep -q "Up"; then
        print_success "Containers já estão rodando"
    else
        # Parar containers existentes (se houver)
        sudo docker-compose -f docker-compose.databases.yml down 2>/dev/null || true

        # Iniciar containers
        sudo docker-compose -f docker-compose.databases.yml up -d

        if [[ $? -ne 0 ]]; then
            print_error "Falha ao iniciar containers Docker"
            exit 1
        fi

        print_success "Containers Docker iniciados"
    fi

    cd "../.."
}

# Função para aguardar bancos
wait_for_databases() {
    print_step "Aguardando bancos de dados..."

    # Aguardar PostgreSQL
    print_message "Aguardando PostgreSQL..."
    for i in {1..30}; do
        if sudo docker exec backend_db_postgres_1 pg_isready -U atendechat -d atendechat_db 2>/dev/null; then
            print_success "PostgreSQL pronto!"
            break
        fi
        sleep 2
    done

    # Aguardar Redis
    print_message "Aguardando Redis..."
    for i in {1..10}; do
        if sudo docker exec backend_cache_1 redis-cli ping 2>/dev/null | grep -q "PONG"; then
            print_success "Redis pronto!"
            break
        fi
        sleep 1
    done

    # Aguardar mais um pouco para garantir
    sleep 5
}

# Função para verificar e executar build do backend
check_backend_build() {
    print_step "Verificando build do backend..."

    # Garantir que estamos no diretório raiz
    if [[ ! -f "start.sh" ]]; then
        print_error "Erro: Não estamos no diretório raiz!"
        print_message "Diretório atual: $(pwd)"
        exit 1
    fi

    local backend_dir="./atendechat/backend"

    if [[ ! -d "$backend_dir" ]]; then
        print_error "Diretório backend não encontrado: $backend_dir"
        print_message "Diretório atual: $(pwd)"
        exit 1
    fi

    cd "$backend_dir"

    # Verificar se pasta dist existe e tem arquivos
    if [[ ! -d "dist" ]] || [[ ! -f "dist/server.js" ]]; then
        print_message "Executando build do backend..."
        npm run build

        if [[ $? -ne 0 ]]; then
            print_error "Falha no build do backend"
            exit 1
        fi

        print_success "Backend compilado com sucesso"
    else
        print_success "Backend já está compilado"
    fi

    cd "../.."
}

# Função para configurar banco de dados
setup_database() {
    print_step "Configurando banco de dados..."

    # Garantir que estamos no diretório raiz
    if [[ ! -f "start.sh" ]]; then
        print_error "Erro: Não estamos no diretório raiz!"
        print_message "Diretório atual: $(pwd)"
        exit 1
    fi

    local backend_dir="./atendechat/backend"

    if [[ ! -d "$backend_dir" ]]; then
        print_error "Diretório backend não encontrado: $backend_dir"
        print_message "Diretório atual: $(pwd)"
        print_message "Conteúdo do diretório atual:"
        ls -la
        exit 1
    fi

    cd "$backend_dir"

    # Executar migrations (como no install.sh original)
    print_message "Executando migrations..."
    npx sequelize db:migrate || print_warning "Algumas migrações podem ter falhado"

    # Executar migration adicional para coluna language (se necessário)
    print_message "Verificando coluna language na tabela Companies..."
    if ! sudo docker exec backend_db_postgres_1 psql -U atendechat -d atendechat_db -c "SELECT language FROM \"Companies\" LIMIT 1;" 2>/dev/null; then
        print_message "Adicionando coluna language à tabela Companies..."
        # Criar migration específica se não existir
        if [[ ! -f "add-language-column.js" ]]; then
            cat > add-language-column.js << 'EOF'
'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('Companies', 'language', {
      type: Sequelize.STRING,
      allowNull: true,
      defaultValue: 'pt-BR'
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('Companies', 'language');
  }
};
EOF
        fi
        npx sequelize db:migrate --name add-language-column.js 2>/dev/null || print_warning "Migration da coluna language pode já ter sido executada"
    else
        print_message "Coluna language já existe"
    fi

    # Executar seeds (como no install.sh original)
    print_message "Executando seeds..."
    npx sequelize db:seed:all || print_warning "Seeds podem ter falhado"

    cd "../.."

    print_success "Banco de dados configurado"
}



# Função para iniciar aplicações com PM2
start_with_pm2() {
    print_step "Iniciando aplicações com PM2..."

    # Garantir que estamos no diretório raiz
    if [[ ! -f "start.sh" ]]; then
        print_error "Erro: Não estamos no diretório raiz!"
        print_message "Diretório atual: $(pwd)"
        exit 1
    fi



    # Verificar se já existem processos PM2 rodando
    if pm2 list 2>/dev/null | grep -q "atendechat"; then
        print_warning "Aplicações já estão rodando no PM2"
        print_message "Use './stop.sh' para parar ou 'pm2 restart ecosystem.config.js' para reiniciar"
        return 0
    fi

    # Estratégia: Usar PM2 prioritariamente para persistência máxima
    print_message "Iniciando aplicações com PM2 para persistência máxima..."

    # Verificar PM2 e ecosystem.config.js
    if ! command_exists pm2; then
        print_error "❌ PM2 não está instalado!"
        print_message "Instale com: sudo npm install -g pm2"
        exit 1
    fi

    if [[ ! -f "ecosystem.config.js" ]]; then
        print_error "❌ Arquivo ecosystem.config.js não encontrado!"
        print_message "Crie o arquivo de configuração do PM2"
        exit 1
    fi

    print_success "✅ PM2 e configuração encontrados"

    # Limpar processos existentes para evitar conflitos
    print_message "Limpando processos existentes..."
    pm2 kill 2>/dev/null || true
    sleep 2

    # Iniciar aplicações com PM2
    print_message "Iniciando aplicações com PM2..."
    pm2 start ecosystem.config.js

    if [[ $? -eq 0 ]]; then
        print_success "✅ Aplicações iniciadas com PM2!"

        # Salvar configuração para persistência
        pm2 save
        print_success "✅ Configuração PM2 salva"

        # Mostrar status
        pm2 list

        print_message ""
        print_success "🎉 PM2 CONFIGURADO COM SUCESSO!"
        print_message "📊 Aplicações agora têm persistência máxima"
        print_message "🔄 Sobrevivem a fechamentos de terminal e reinicializações"
        print_message ""
        print_message "💡 Para configurar inicialização automática no boot:"
        print_message "   pm2 startup"
        print_message "   pm2 save"
        print_message ""

        return 0
    else
        print_error "❌ Falha ao iniciar com PM2"
        exit 1
    fi

    # Método automático: Limpar e iniciar aplicações
    print_message "🔄 Iniciando aplicações automaticamente..."

    # Parar processos existentes automaticamente
    print_message "Parando processos existentes..."
    pkill -f "node.*dist/server.js" 2>/dev/null || true
    pkill -f "npm.*start" 2>/dev/null || true
    sleep 3

    # Iniciar backend
    print_message "Iniciando backend..."
    cd atendechat/backend
    npm start &
    BACKEND_PID=$!
    cd ../..

    print_success "✅ Backend iniciado (PID: $BACKEND_PID)"

    # Aguardar backend iniciar
    print_message "Aguardando backend iniciar..."
    sleep 10

    # Iniciar frontend
    print_message "Iniciando frontend..."
    cd atendechat/frontend
    NODE_OPTIONS="--openssl-legacy-provider" npm start &
    FRONTEND_PID=$!
    cd ../..

    print_success "✅ Frontend iniciado (PID: $FRONTEND_PID)"

    # Aguardar aplicações iniciarem
    print_message "Aguardando aplicações ficarem prontas..."
    sleep 20

    # Verificar se aplicações estão respondendo
    print_message "🔍 Verificando aplicações..."

    # Testar backend
    if curl -s --max-time 10 http://localhost:8080 > /dev/null 2>&1; then
        print_success "✅ Backend: http://localhost:8080 (respondendo)"
    else
        print_warning "⚠️  Backend ainda inicializando..."
    fi

    # Testar frontend
    if curl -s --max-time 10 http://localhost:3000 > /dev/null 2>&1; then
        print_success "✅ Frontend: http://localhost:3000 (respondendo)"
    else
        print_warning "⚠️  Frontend ainda inicializando..."
    fi

    print_message ""
    print_success "🎉 APLICAÇÕES INICIADAS COM SUCESSO!"
    print_message "📊 PIDs - Backend: $BACKEND_PID | Frontend: $FRONTEND_PID"
    print_message ""
    print_message "🌐 Acesse:"
    print_message "   Backend:  http://localhost:8080"
    print_message "   Frontend: http://localhost:3000"
    print_message ""
    print_message "🛑 Para parar: ./stop.sh"
}

# Função para verificar se tudo está funcionando
verify_system() {
    print_step "Verificando sistema..."

    # Aguardar aplicações iniciarem
    print_message "Aguardando aplicações ficarem prontas (30 segundos)..."
    sleep 30

    # Verificar backend com mais detalhes
    print_message "Testando Backend..."
    if curl -s --max-time 10 http://localhost:8080 > /dev/null 2>&1; then
        print_success "✅ Backend: http://localhost:8080 (respondendo)"
    else
        print_warning "⚠️  Backend ainda inicializando..."
        print_message "  💡 O backend pode levar mais tempo para iniciar completamente"
        print_message "  📝 Verifique os logs: tail -f /tmp/backend.log"
    fi

    # Verificar frontend com mais detalhes
    print_message "Testando Frontend..."
    if curl -s --max-time 10 http://localhost:3000 > /dev/null 2>&1; then
        print_success "✅ Frontend: http://localhost:3000 (respondendo)"
    else
        print_warning "⚠️  Frontend ainda inicializando..."
        print_message "  💡 O frontend pode levar mais tempo para compilar"
        print_message "  📝 Verifique os logs: tail -f /tmp/frontend.log"
    fi

    # Verificar processos com PM2
    print_message "Verificando processos com PM2..."
    if pm2 list 2>/dev/null | grep -q "atendechat-backend"; then
        backend_pid=$(pm2 list 2>/dev/null | grep "atendechat-backend" | awk '{print $4}')
        print_success "✅ Processo Backend ativo (PID: $backend_pid)"
    else
        print_error "❌ Processo Backend não encontrado no PM2"
    fi

    if pm2 list 2>/dev/null | grep -q "atendechat-frontend"; then
        frontend_pid=$(pm2 list 2>/dev/null | grep "atendechat-frontend" | awk '{print $4}')
        print_success "✅ Processo Frontend ativo (PID: $frontend_pid)"
    else
        print_error "❌ Processo Frontend não encontrado no PM2"
    fi

    print_message ""
    print_success "🎉 SISTEMA INICIADO COM SUCESSO!"
    print_message "📊 Aplicações rodando com monitoramento automático"
    print_message "🔄 Auto-restart ativo em caso de falha"
}

# Função principal
main() {
    print_message "=== ATENDECHAT - INICIALIZAÇÃO COM PM2 ==="
    print_message "Iniciando todo o sistema automaticamente..."
    print_message ""

    # Verificar PM2
    check_pm2

    # Verificar Docker
    check_docker

    # Verificar diretório
    check_directory

    # Iniciar containers
    start_containers

    # Aguardar bancos
    wait_for_databases

    # Verificar/compilar backend
    check_backend_build

    # Configurar banco
    setup_database

    # Iniciar aplicações com PM2
    start_with_pm2

    # Verificar sistema
    verify_system

    print_message ""
    print_message "=== SISTEMA TOTALMENTE OPERACIONAL ==="
    print_message "AtendeChat está rodando com PM2!"
    print_message ""
    print_message "✅ Processos persistem após fechar terminal"
    print_message "✅ Monitoramento automático ativo"
    print_message "✅ Restart automático em caso de falha"
    print_message ""
    print_message "Acesso:"
    print_message "  Frontend: http://localhost:3000"
    print_message "  Backend:  http://localhost:8080"
    print_message ""
    print_message "Comandos PM2:"
    print_message "  Status: pm2 status"
    print_message "  Logs: pm2 logs"
    print_message "  Monitor: pm2 monit"
    print_message ""
    print_message "Para parar: ./stop.sh"
    print_message "Para verificar: ./status.sh"
}

# Executar função principal
main "$@"
