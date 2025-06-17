# PowerShell Script para criar estrutura de pastas do projeto Unlock
# Execute este script na raiz do projeto Flutter

Write-Host "Criando estrutura de pastas para o projeto Unlock..." -ForegroundColor Green

# Função para criar diretório se não existir
function New-DirectoryIfNotExists {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "Criado: $Path" -ForegroundColor Cyan
    } else {
        Write-Host "Já existe: $Path" -ForegroundColor Yellow
    }
}

# Criar estrutura principal
$folders = @(
    # Core (configurações centrais)
    "lib/core",
    "lib/core/constants",
    "lib/core/theme", 
    "lib/core/utils",
    "lib/core/router",
    "lib/core/validators",
    "lib/core/extensions",
    
    # Features (funcionalidades por módulo)
    "lib/features",
    "lib/features/auth",
    "lib/features/auth/screens",
    "lib/features/auth/widgets", 
    "lib/features/auth/providers",
    
    "lib/features/onboarding",
    "lib/features/onboarding/screens",
    "lib/features/onboarding/widgets",
    "lib/features/onboarding/providers",
    
    "lib/features/home",
    "lib/features/home/screens", 
    "lib/features/home/widgets",
    "lib/features/home/providers",
    
    "lib/features/missions",
    "lib/features/missions/screens",
    "lib/features/missions/widgets", 
    "lib/features/missions/providers",
    "lib/features/missions/models",
    
    "lib/features/profile",
    "lib/features/profile/screens",
    "lib/features/profile/widgets",
    "lib/features/profile/providers",
    
    "lib/features/connections",
    "lib/features/connections/screens", 
    "lib/features/connections/widgets",
    "lib/features/connections/providers",
    "lib/features/connections/models",
    
    "lib/features/shop",
    "lib/features/shop/screens",
    "lib/features/shop/widgets",
    "lib/features/shop/providers",
    
    "lib/features/games",
    "lib/features/games/screens",
    "lib/features/games/widgets", 
    "lib/features/games/providers",
    "lib/features/games/models",
    
    # Models (modelos de dados globais)
    "lib/models",
    
    # Providers (providers globais)
    "lib/providers",
    
    # Services (serviços globais)
    "lib/services",
    "lib/services/security",
    "lib/services/api",
    "lib/services/cache",
    "lib/services/notifications",
    
    # Shared (componentes compartilhados)
    "lib/shared",
    "lib/shared/widgets",
    "lib/shared/widgets/buttons",
    "lib/shared/widgets/cards", 
    "lib/shared/widgets/forms",
    "lib/shared/widgets/loading",
    "lib/shared/widgets/dialogs",
    "lib/shared/screens",
    "lib/shared/utils",
    
    # Assets organization
    "assets",
    "assets/images",
    "assets/images/avatars",
    "assets/images/icons", 
    "assets/images/backgrounds",
    "assets/animations",
    "assets/fonts",
    "assets/sounds",
    
    # Configuration files
    "config",
    "config/firebase",
    "config/environments",
    
    # Documentation
    "docs",
    "docs/api",
    "docs/architecture", 
    "docs/features",
    
    # Tests
    "test",
    "test/unit",
    "test/widget", 
    "test/integration",
    "test/mocks",
    
    # Scripts
    "scripts",
    "scripts/build",
    "scripts/deploy"
)

# Criar todas as pastas
foreach ($folder in $folders) {
    New-DirectoryIfNotExists -Path $folder
}

Write-Host ""
Write-Host "Criando arquivos de documentação da estrutura..." -ForegroundColor Green

# Criar arquivo README para cada feature
$features = @("auth", "onboarding", "home", "missions", "profile", "connections", "shop", "games")

foreach ($feature in $features) {
    $readmePath = "lib/features/$feature/README.md"
    if (!(Test-Path $readmePath)) {
        $readmeContent = @"
#Feature: $($feature.ToUpper())

## Estrutura
- `screens/` - Telas da funcionalidade
- `widgets/` - Widgets específicos
- `providers/` - Gerenciamento de estado
- `models/` - Modelos de dados específicos (se aplicável)

## Responsabilidades
TODO: Documentar responsabilidades desta feature

## Dependências
TODO: Listar dependências de outras features

## Implementação
- [ ] Screens
- [ ] Widgets  
- [ ] Providers
- [ ] Models
- [ ] Testes
"@
        $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
        Write-Host "Criado: $readmePath" -ForegroundColor Cyan
    }
}

# Criar arquivo de arquitetura
$archPath = "docs/architecture/README.md"
if (!(Test-Path $archPath)) {
    $archContent = @"
#  Arquitetura do Projeto Unlock

## Princípios
- **Clean Architecture**: Separação clara de responsabilidades
- **Feature-Based**: Organização por funcionalidades
- **Provider Pattern**: Gerenciamento de estado com Riverpod
- **Single Responsibility**: Cada arquivo tem uma responsabilidade específica

## Estrutura de Pastas

### `/lib/core/`
Configurações centrais e utilitários compartilhados por todo o app.

### `/lib/features/`
Funcionalidades organizadas em módulos independentes.

### `/lib/shared/`
Componentes reutilizáveis entre diferentes features.

### `/lib/services/`
Serviços globais (Firebase, APIs, Cache, etc.).

## Fluxo de Dados
User Interaction → Widget → Provider → Service → Backend → Provider → Widget

## Convenções de Nomenclatura
- Arquivos: `snake_case.dart`
- Classes: `PascalCase`
- Variáveis: `camelCase`
- Constantes: `UPPER_SNAKE_CASE`
"@
    $archContent | Out-File -FilePath $archPath -Encoding UTF8
    Write-Host "Criado: $archPath" -ForegroundColor Cyan
}

# Criar .gitkeep para pastas vazias importantes
$gitkeepFolders = @(
    "assets/images/avatars",
    "assets/animations", 
    "assets/sounds",
    "test/mocks",
    "config/environments"
)

foreach ($folder in $gitkeepFolders) {
    $gitkeepPath = "$folder/.gitkeep"
    if (!(Test-Path $gitkeepPath)) {
        "" | Out-File -FilePath $gitkeepPath -Encoding UTF8
        Write-Host "Criado: $gitkeepPath" -ForegroundColor Cyan
    }
}

# Criar arquivo de configuração de ambiente exemplo
$envExamplePath = "config/environments/.env.example"
if (!(Test-Path $envExamplePath)) {
    $envContent = @"
# Firebase Configuration
FIREBASE_API_KEY=your_api_key_here
FIREBASE_APP_ID=your_app_id_here
FIREBASE_PROJECT_ID=your_project_id_here

# Development
DEBUG_MODE=true
LOG_LEVEL=debug

# Features Flags
ENABLE_ANALYTICS=false
ENABLE_CRASHLYTICS=false
ENABLE_PERFORMANCE=false

# API Configuration  
API_BASE_URL=https://api.unlock.app
API_TIMEOUT=30000
"@
    $envContent | Out-File -FilePath $envExamplePath -Encoding UTF8
    Write-Host "Criado: $envExamplePath" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Estrutura de pastas criada com sucesso!" -ForegroundColor Green
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Mover arquivos existentes para a nova estrutura" -ForegroundColor White
Write-Host "   2. Atualizar imports nos arquivos" -ForegroundColor White  
Write-Host "   3. Implementar sistema de logs" -ForegroundColor White
Write-Host "   4. Configurar ambientes (.env)" -ForegroundColor White
Write-Host ""