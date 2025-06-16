# ===================================================================
# SCRIPT DE PADRONIZAÇÃO - UNLOCK APP
# ===================================================================

param(
    [string]$ProjectPath = ".",
    [switch]$DryRun = $false
)

# Configurar encoding UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "🔓 Padronização do App UNLOCK" -ForegroundColor Green
Write-Host "📁 Projeto: $ProjectPath" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "⚠️  MODO DRY RUN - Simulação apenas" -ForegroundColor Yellow
}

Set-Location $ProjectPath

# ===================================================================
# FUNÇÕES AUXILIARES
# ===================================================================

function Write-Step {
    param([string]$Step, [string]$Description)
    Write-Host "`n🔸 $Step $Description" -ForegroundColor Cyan
}

function Replace-InFile {
    param(
        [string]$FilePath,
        [hashtable]$Replacements,
        [string]$Description
    )
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $modified = $false
        
        foreach ($replacement in $Replacements.GetEnumerator()) {
            $oldValue = $replacement.Key
            $newValue = $replacement.Value
            
            if ($content -match [regex]::Escape($oldValue)) {
                $content = $content -replace [regex]::Escape($oldValue), $newValue
                $modified = $true
                Write-Host "  ✅ $Description - $oldValue → $newValue" -ForegroundColor Green
            }
        }
        
        if ($modified -and !$DryRun) {
            $content | Out-File -FilePath $FilePath -Encoding UTF8 -NoNewline
        }
        
        return $modified
    }
    return $false
}

function Replace-InAllDartFiles {
    param([hashtable]$Replacements, [string]$Description)
    
    $dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue
    $totalModified = 0
    
    foreach ($file in $dartFiles) {
        $modified = Replace-InFile -FilePath $file.FullName -Replacements $Replacements -Description $Description
        if ($modified) { $totalModified++ }
    }
    
    Write-Host "  📊 Total de arquivos modificados: $totalModified" -ForegroundColor White
}

# ===================================================================
# ETAPA 1: PADRONIZAR NOME DO APP
# ===================================================================

Write-Step "ETAPA 1:" "Padronizando nome do app para UNLOCK"

$appNameReplacements = @{
    "PetCare" = "Unlock"
    "Social Match" = "Unlock" 
    "SocialMatchApp" = "UnlockApp"
    "'PetCare'" = "'Unlock'"
    '"PetCare"' = '"Unlock"'
    "'Social Match'" = "'Unlock'"
    '"Social Match"' = '"Unlock"'
    "Social Match:" = "Unlock:"
    "🚀 PetCare:" = "🚀 Unlock:"
    "🎉 Unlock:" = "🎉 Unlock:" # Já está correto
}

Replace-InAllDartFiles -Replacements $appNameReplacements -Description "Nome do app"

# ===================================================================
# ETAPA 2: REMOVER REFERÊNCIAS A PET VIRTUAL
# ===================================================================

Write-Step "ETAPA 2:" "Removendo referências a pet virtual"

# Substituir itens de pet por itens sociais no constants.dart
if (Test-Path "lib/utils/constants.dart") {
    Write-Host "🧹 Limpando constants.dart..." -ForegroundColor Yellow
    
    $petToSocialItems = @{
        # Itens de comida → itens sociais
        "Ração Básica" = "Super Like"
        "Comida Premium" = "Boost de Visibilidade" 
        "Petisco Especial" = "Destaque Premium"
        
        # Brinquedos → recursos sociais  
        "Bola" = "Icebreaker"
        "Corda" = "Pergunta Personalizada"
        
        # Medicina → recursos de conexão
        "Vitamina" = "Verificação de Perfil"
        "Poção Cura" = "Reset de Matches"
        
        # Efeitos de pet → efeitos sociais
        "'hunger'" = "'visibility'"
        "'health'" = "'matches'"  
        "'energy'" = "'popularity'"
        "'happiness'" = "'appeal'"
        
        # Categorias
        "'comida'" = "'boost'"
        "'brinquedo'" = "'interaction'"
        "'medicina'" = "'premium'"
        "'acessório'" = "'cosmetic'"
        
        # Emojis de pet → emojis sociais
        "🥣" = "💫"  # ração → super like
        "🥩" = "🚀"  # comida → boost
        "🦴" = "✨"  # petisco → destaque  
        "⚽" = "💭"  # bola → icebreaker
        "🧸" = "❓"  # corda → pergunta
        "💊" = "✅"  # vitamina → verificação
        "🧪" = "🔄"  # poção → reset
    }
    
    Replace-InFile -FilePath "lib/utils/constants.dart" -Replacements $petToSocialItems -Description "Itens sociais"
}

# Remover missões de pet
$petMissionReplacements = @{
    "Alimentar 3 vezes" = "Enviar 3 mensagens"
    "Brincar 5 vezes" = "Fazer 5 conexões"
    "Cuidar 10 vezes" = "Responder 10 perguntas"
    "Usar 5 itens" = "Usar 5 boosts"
    "Gerar pet único" = "Completar perfil"
    "Evolua seu pet" = "Alcance nível 5"
    "Adote um Pet" = "Desbloqueie uma Conexão"
    "Dragon Bebê" = "Perfil Especial"
    "novo companheiro" = "nova conexão especial"
}

Replace-InAllDartFiles -Replacements $petMissionReplacements -Description "Missões sociais"

# Remover variáveis relacionadas a pet
$petVariableReplacements = @{
    "activePetIndex" = "activeConnectionIndex"
    "petType" = "connectionType"  
    "petEmoji" = "connectionEmoji"
    "feedPet" = "sendMessage"
    "playWithPet" = "interactWith"
}

Replace-InAllDartFiles -Replacements $petVariableReplacements -Description "Variáveis sociais"

# ===================================================================
# ETAPA 3: PADRONIZAR COMENTÁRIOS PARA PORTUGUÊS
# ===================================================================

Write-Step "ETAPA 3:" "Padronizando comentários para português"

$commentReplacements = @{
    # Comentários técnicos comuns
    "// Animation Controllers" = "// Controladores de animação"
    "// State Management" = "// Gerenciamento de estado"
    "// Animations" = "// Animações"
    "// Loading state" = "// Estado de carregamento"
    "// Error handling" = "// Tratamento de erros"
    "// Navigation" = "// Navegação"
    "// User operations" = "// Operações de usuário"
    "// UI Constants" = "// Constantes de UI"
    "// Helper methods" = "// Métodos auxiliares"
    "// Configuration" = "// Configuração"
    "// Initialization" = "// Inicialização"
    "// Main app widget" = "// Widget principal da aplicação"
    "// Theme configuration" = "// Configuração de tema"
    "// Router configuration" = "// Configuração de rotas"
    
    # Comentários específicos do projeto
    "// TODO: Implement" = "// TODO: Implementar"
    "// FIXME:" = "// CORRIGIR:"
    "// NOTE:" = "// NOTA:"
    "// WARNING:" = "// AVISO:"
    "// Building" = "// Construindo"
    "// Creating" = "// Criando"
    "// Updating" = "// Atualizando"
    "// Loading" = "// Carregando"
    
    # Comentários de debug
    "// Debug info" = "// Informações de debug"
    "// Debug mode" = "// Modo debug"
    "// For debugging" = "// Para debug"
}

Replace-InAllDartFiles -Replacements $commentReplacements -Description "Comentários em português"

# ===================================================================
# ETAPA 4: PADRONIZAR NOMENCLATURA DE VARIÁVEIS
# ===================================================================

Write-Step "ETAPA 4:" "Padronizando nomenclatura de variáveis"

$variableReplacements = @{
    # Padronizar nomes de usuário
    "userName" = "displayName"  # Usar sempre displayName
    "user_name" = "displayName"
    "username" = "displayName"  # Quando não for field do modelo
    
    # Padronizar conexões
    "connectionData" = "connectionModel"
    "connection_data" = "connectionModel"
    "userData" = "userModel"
    "user_data" = "userModel"
    
    # Padronizar estados
    "isLoggedIn" = "isAuthenticated"
    "loggedIn" = "authenticated"
    "hasConnection" = "isConnected"
    
    # Manter codinome (decisão do usuário)
    # "codinome" mantém como está
}

Replace-InAllDartFiles -Replacements $variableReplacements -Description "Nomenclatura de variáveis"

# ===================================================================
# ETAPA 5: CORRIGIR STRINGS DO USUÁRIO
# ===================================================================

Write-Step "ETAPA 5:" "Corrigindo strings visíveis ao usuário"

$userStringReplacements = @{
    # Mensagens de boas-vindas
    "Bem-vindo ao PetCare" = "Bem-vindo ao Unlock"
    "Bem-vindo ao Social Match" = "Bem-vindo ao Unlock"
    
    # Descrições do app
    "Conecte-se de Verdade" = "Desbloqueie Conexões Reais"
    "Cuidando do seu pet" = "Desbloqueando conexões"
    "pet com carinho" = "pessoas especiais"
    
    # Textos relacionados a pet
    "Meus Pets" = "Minhas Conexões"
    "Adicionar Pet" = "Nova Conexão"
    "Status do Pet" = "Status das Conexões"
    "Cuidados do Pet" = "Gerenciar Conexões"
    
    # Missões e gamificação
    "Missão Especial: Adote um Pet" = "Missão Especial: Desbloqueie uma Conexão"
    "desbloquear seu novo companheiro" = "desbloquear sua nova conexão"
    
    # Mensagens de sistema
    "Pet inicializado" = "Sistema inicializado"
    "Pet atualizado" = "Perfil atualizado"
}

Replace-InAllDartFiles -Replacements $userStringReplacements -Description "Strings do usuário"

# ===================================================================
# ETAPA 6: PADRONIZAR NOMES DE CLASSES E ENUMS
# ===================================================================

Write-Step "ETAPA 6:" "Padronizando nomes de classes e enums"

$classReplacements = @{
    # Padronizar sufixos de classes
    "AuthState" = "AuthState"  # Já correto
    "UserState" = "UserState"  # Já correto
    "AppState" = "AppState"    # Já correto
    
    # Corrigir nomes inconsistentes
    "UnlockApp" = "UnlockApp"  # Principal widget
    "SocialMatchApp" = "UnlockApp"  # Se ainda existir
    
    # Padronizar providers
    "authProvider" = "authProvider"     # Já correto
    "userProvider" = "userProvider"     # Já correto
    "themeProvider" = "themeProvider"   # Já correto
}

Replace-InAllDartFiles -Replacements $classReplacements -Description "Nomes de classes"

# ===================================================================
# ETAPA 7: RELATÓRIO FINAL
# ===================================================================

Write-Step "ETAPA 7:" "Relatório da padronização"

Write-Host "`n📊 RESUMO DA PADRONIZAÇÃO:" -ForegroundColor Green
Write-Host "✅ Nome do app: UNLOCK" -ForegroundColor White
Write-Host "✅ Referências a pet removidas" -ForegroundColor White
Write-Host "✅ Itens de pet → itens sociais" -ForegroundColor White
Write-Host "✅ Missões de pet → missões sociais" -ForegroundColor White
Write-Host "✅ Comentários em português" -ForegroundColor White
Write-Host "✅ Nomenclatura padronizada" -ForegroundColor White
Write-Host "✅ Strings do usuário corrigidas" -ForegroundColor White

Write-Host "`n🎯 CONCEITO DO APP UNLOCK:" -ForegroundColor Cyan
Write-Host "🔓 Usuários usam codinomes fictícios" -ForegroundColor White
Write-Host "🧠 Fazem testes de afinidade" -ForegroundColor White  
Write-Host "✅ Desbloqueiam perfis reais ao passar nos testes" -ForegroundColor White
Write-Host "💫 Ganham boosts e recursos sociais" -ForegroundColor White

Write-Host "`n🔧 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1. Revisar arquivo constants.dart" -ForegroundColor White
Write-Host "2. Testar build: flutter run" -ForegroundColor White
Write-Host "3. Ajustar imports se necessário" -ForegroundColor White
Write-Host "4. Implementar sistema de testes de afinidade" -ForegroundColor White

if (!$DryRun) {
    Write-Host "`n⚠️  Execute: flutter clean && flutter pub get" -ForegroundColor Red
} else {
    Write-Host "`n🔄 Para executar de verdade, remova -DryRun" -ForegroundColor Yellow
}

Write-Host "`n🔓 Padronização do UNLOCK concluída!" -ForegroundColor Green