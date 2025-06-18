# ================================================================================================
# SCRIPT POWERSHELL - CRIAÇÃO ESTRUTURA FASE 3
# App: Unlock - Home e Missões Gamificadas
# ================================================================================================

Write-Host "Criando estrutura da Fase 3 - Home e Missões..." -ForegroundColor Cyan

# Verificar se estamos no diretório correto
if (-not (Test-Path "lib")) {
    Write-Host "Erro: Execute o script na raiz do projeto Flutter (onde está o pubspec.yaml)" -ForegroundColor Red
    exit 1
}

Write-Host "Criando estrutura de pastas..." -ForegroundColor Yellow

# ================================================================================================
# FEATURES - HOME (expandir existente)
# ================================================================================================
$homeFeature = @(
    "lib/features/home/screens",
    "lib/features/home/widgets", 
    "lib/features/home/providers"
)

foreach ($folder in $homeFeature) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "$folder" -ForegroundColor Green
    } else {
        Write-Host "$folder (já existe)" -ForegroundColor Gray
    }
}

# ================================================================================================
# FEATURES - MISSIONS (nova)
# ================================================================================================
$missionsFeature = @(
    "lib/features/missions",
    "lib/features/missions/models",
    "lib/features/missions/screens", 
    "lib/features/missions/widgets",
    "lib/features/missions/providers",
    "lib/features/missions/services"
)

foreach ($folder in $missionsFeature) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    Write-Host "$folder" -ForegroundColor Green
}

# ================================================================================================
# FEATURES - REWARDS (nova)
# ================================================================================================
$rewardsFeature = @(
    "lib/features/rewards",
    "lib/features/rewards/models",
    "lib/features/rewards/providers", 
    "lib/features/rewards/services"
)

foreach ($folder in $rewardsFeature) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    Write-Host "$folder" -ForegroundColor Green
}

# ================================================================================================
# FEATURES - NAVIGATION (nova)
# ================================================================================================
$navigationFeature = @(
    "lib/features/navigation",
    "lib/features/navigation/widgets",
    "lib/features/navigation/providers"
)

foreach ($folder in $navigationFeature) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    Write-Host "$folder" -ForegroundColor Green
}

# ================================================================================================
# CORE EXPANSÕES
# ================================================================================================
$coreExpansions = @(
    "lib/core/constants",
    "lib/core/utils", 
    "lib/core/services"
)

foreach ($folder in $coreExpansions) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "$folder" -ForegroundColor Green
    } else {
        Write-Host "$folder (já existe)" -ForegroundColor Gray
    }
}

# ================================================================================================
# CRIAR ARQUIVOS README INICIAIS
# ================================================================================================
Write-Host "Criando arquivos README..." -ForegroundColor Yellow

$readmeContent = @"
# Feature README
Implementado na Fase 3 - Home e Missões Gamificadas

## Status: Em Desenvolvimento 

## Arquivos principais:
- [ ] Models
- [ ] Providers  
- [ ] Services
- [ ] Widgets
- [ ] Screens

Atualizado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')
"@

# README para features novas
$newFeatures = @("missions", "rewards", "navigation")
foreach ($feature in $newFeatures) {
    $readmePath = "lib/features/$feature/README.md"
    $readmeContent.Replace("Feature README", "$feature README".ToUpper()) | Out-File -FilePath $readmePath -Encoding UTF8
    Write-Host "$readmePath" -ForegroundColor Cyan
}

# ================================================================================================
# CRIAR ARQUIVOS .gitkeep PARA PASTAS VAZIAS
# ================================================================================================
$emptyFolders = @(
    "lib/features/missions/models",
    "lib/features/missions/screens",
    "lib/features/missions/widgets", 
    "lib/features/missions/providers",
    "lib/features/missions/services",
    "lib/features/rewards/models",
    "lib/features/rewards/providers",
    "lib/features/rewards/services",
    "lib/features/navigation/widgets",
    "lib/features/navigation/providers"
)

foreach ($folder in $emptyFolders) {
    $gitkeepPath = "$folder/.gitkeep"
    "" | Out-File -FilePath $gitkeepPath -Encoding UTF8
}

# ================================================================================================
# RESUMO FINAL
# ================================================================================================
Write-Host ""
Write-Host " ESTRUTURA FASE 3 CRIADA COM SUCESSO!" -ForegroundColor Green
Write-Host ""
Write-Host "Resumo:" -ForegroundColor Cyan
Write-Host "   • Features expandidas: home" -ForegroundColor White  
Write-Host "   • Features novas: missions, rewards, navigation" -ForegroundColor White
Write-Host "   • Core expansions: constants, utils, services" -ForegroundColor White
Write-Host ""
Write-Host " Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Copiar arquivos de código dos artefatos" -ForegroundColor White
Write-Host "   2. Executar flutter pub get" -ForegroundColor White
Write-Host "   3. Verificar imports" -ForegroundColor White
Write-Host "   4. Testar compilação" -ForegroundColor White
Write-Host ""
Write-Host " Estrutura pronta para implementação da Fase 3!" -ForegroundColor Green