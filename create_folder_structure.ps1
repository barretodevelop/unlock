# PowerShell Script - Criar estrutura Profile & Settings
# Projeto: Unlock App
# Autor: Sistema de Profile e Settings
# Data: 2025

param(
    [string]$ProjectPath = ".",
    [switch]$Force
)

# Configuracoes
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Cores para output (sem emojis)
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }

# Funcao para criar diretorio
function New-DirectoryIfNotExists {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Info "Diretorio criado: $Path"
    } else {
        Write-Warning "Diretorio ja existe: $Path"
    }
}

# Funcao para criar arquivo vazio
function New-EmptyFileIfNotExists {
    param(
        [string]$Path,
        [string]$Content = ""
    )
    
    if (-not (Test-Path $Path) -or $Force) {
        $Content | Out-File -FilePath $Path -Encoding UTF8
        Write-Info "Arquivo criado: $Path"
    } else {
        Write-Warning "Arquivo ja existe: $Path"
    }
}

# Funcao principal
function Initialize-ProfileSettingsStructure {
    param([string]$BasePath)
    
    Write-Success "INICIANDO CRIACAO DA ESTRUTURA PROFILE & SETTINGS"
    Write-Info "Caminho base: $BasePath"
    Write-Info "Modo Force: $Force"
    
    try {
        # Definir estrutura de diretorios
        $directories = @(
            # Features - Profile
            "lib/features/profile",
            "lib/features/profile/screens",
            "lib/features/profile/widgets", 
            "lib/features/profile/providers",
            "lib/features/profile/models",
            
            # Features - Settings
            "lib/features/settings",
            "lib/features/settings/screens",
            "lib/features/settings/widgets",
            "lib/features/settings/providers", 
            "lib/features/settings/models",
            
            # Shared Widgets
            "lib/shared",
            "lib/shared/widgets",
            
            # Core (se nao existir)
            "lib/core",
            "lib/core/utils",
            "lib/providers"
        )
        
        # Criar diretorios
        Write-Info "Criando estrutura de diretorios..."
        foreach ($dir in $directories) {
            $fullPath = Join-Path $BasePath $dir
            New-DirectoryIfNotExists $fullPath
        }
        
        # Definir arquivos para criar
        $files = @{
            # Profile Feature
            "lib/features/profile/screens/profile_screen.dart" = @"
// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(
        child: Text('Profile Screen - Em desenvolvimento'),
      ),
    );
  }
}
"@
            
            "lib/features/profile/widgets/profile_header.dart" = @"
// lib/features/profile/widgets/profile_header.dart
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
"@
            
            "lib/features/profile/widgets/profile_stats.dart" = @"
// lib/features/profile/widgets/profile_stats.dart
import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
"@
            
            "lib/features/profile/widgets/profile_info_card.dart" = @"
// lib/features/profile/widgets/profile_info_card.dart
import 'package:flutter/material.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
"@
            
            "lib/features/profile/providers/profile_provider.dart" = @"
// lib/features/profile/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref),
);

class ProfileState {
  const ProfileState();
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._ref) : super(const ProfileState());
  final Ref _ref;
}
"@
            
            # Settings Feature
            "lib/features/settings/screens/settings_screen.dart" = @"
// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(
        child: Text('Settings Screen - Em desenvolvimento'),
      ),
    );
  }
}
"@
            
            "lib/features/settings/widgets/settings_tile.dart" = @"
// lib/features/settings/widgets/settings_tile.dart
import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
"@
            
            "lib/features/settings/widgets/theme_toggle.dart" = @"
// lib/features/settings/widgets/theme_toggle.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Placeholder();
  }
}
"@
            
            "lib/features/settings/widgets/notification_toggle.dart" = @"
// lib/features/settings/widgets/notification_toggle.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationToggle extends ConsumerWidget {
  const NotificationToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Placeholder();
  }
}
"@
            
            "lib/features/settings/models/settings_model.dart" = @"
// lib/features/settings/models/settings_model.dart

class SettingsModel {
  final bool isDarkTheme;
  final bool notificationsEnabled;
  
  const SettingsModel({
    this.isDarkTheme = false,
    this.notificationsEnabled = true,
  });
  
  SettingsModel copyWith({
    bool? isDarkTheme,
    bool? notificationsEnabled,
  }) {
    return SettingsModel(
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
"@
            
            "lib/features/settings/providers/settings_provider.dart" = @"
// lib/features/settings/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/settings/models/settings_model.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (ref) => SettingsNotifier(ref),
);

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier(this._ref) : super(const SettingsModel());
  final Ref _ref;
  
  Future<void> toggleTheme() async {
    state = state.copyWith(isDarkTheme: !state.isDarkTheme);
  }
  
  Future<void> toggleNotifications() async {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }
}
"@
            
            # Shared Widgets
            "lib/shared/widgets/user_avatar.dart" = @"
// lib/shared/widgets/user_avatar.dart
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  
  const UserAvatar({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      child: const Icon(Icons.person),
    );
  }
}
"@
            
            "lib/shared/widgets/stat_card.dart" = @"
// lib/shared/widgets/stat_card.dart
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
"@
            
            "lib/shared/widgets/themed_card.dart" = @"
// lib/shared/widgets/themed_card.dart
import 'package:flutter/material.dart';

class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  
  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
"@
            
            # README files
            "lib/features/profile/README.md" = @"
# Feature: PROFILE

## Estrutura
- screens/ - Telas da funcionalidade
- widgets/ - Widgets especificos
- providers/ - Gerenciamento de estado
- models/ - Modelos de dados especificos (se aplicavel)

## Responsabilidades
- Exibicao do perfil do usuario
- Edicao de informacoes pessoais
- Visualizacao de estatisticas
- Gerenciamento de avatar

## Dependencias
- auth_provider (dados do usuario)
- theme_provider (tema da aplicacao)

## Implementacao
- [x] Screens
- [x] Widgets  
- [x] Providers
- [ ] Models
- [ ] Testes
"@
            
            "lib/features/settings/README.md" = @"
# Feature: SETTINGS

## Estrutura
- screens/ - Telas da funcionalidade
- widgets/ - Widgets especificos
- providers/ - Gerenciamento de estado
- models/ - Modelos de dados especificos

## Responsabilidades
- Configuracoes de tema (dark/light)
- Configuracoes de notificacoes
- Logout do usuario
- Configuracoes gerais do app

## Dependencias
- theme_provider (controle de tema)
- auth_provider (logout)
- shared_preferences (persistencia)

## Implementacao
- [x] Screens
- [x] Widgets  
- [x] Providers
- [x] Models
- [ ] Testes
"@
            
            "lib/shared/widgets/README.md" = @"
# Shared Widgets

## Proposito
Widgets reutilizaveis em toda a aplicacao

## Widgets Incluidos
- UserAvatar - Avatar do usuario
- StatCard - Card de estatisticas  
- ThemedCard - Card que segue o tema

## Uso
Importar diretamente nos arquivos que precisam dos widgets

## Convencoes
- Todos os widgets devem suportar tema dark/light
- Devem ser parametrizaveis e reutilizaveis
- Incluir documentacao inline
"@
        }
        
        # Criar arquivos
        Write-Info "Criando arquivos base..."
        foreach ($file in $files.Keys) {
            $fullPath = Join-Path $BasePath $file
            $content = $files[$file]
            New-EmptyFileIfNotExists $fullPath $content
        }
        
        # Criar .gitkeep para diretorios vazios (se necessario)
        $emptyDirs = @(
            "lib/features/profile/models"
        )
        
        Write-Info "Criando .gitkeep para diretorios vazios..."
        foreach ($dir in $emptyDirs) {
            $fullPath = Join-Path $BasePath $dir
            $gitkeepPath = Join-Path $fullPath ".gitkeep"
            New-EmptyFileIfNotExists $gitkeepPath "# Manter diretorio no Git"
        }
        
        # Criar arquivo de configuracao
        $configContent = @"
# Profile & Settings Feature Configuration
# Gerado automaticamente em: $(Get-Date)

## Estrutura Criada:
- Features: Profile, Settings
- Widgets: Shared widgets reutilizaveis
- Providers: Gerenciamento de estado

## Proximos Passos:
1. Copiar implementacoes completas dos artefatos
2. Atualizar imports conforme necessario
3. Testar integracao com AuthProvider existente
4. Configurar rotas no sistema de navegacao
5. Testar tema dark/light

## Observacoes:
- Todos os arquivos foram criados com estrutura basica
- READMEs incluem documentacao de cada feature
- Estrutura segue padrao modular do projeto
"@
        
        $configPath = Join-Path $BasePath "profile_settings_config.md"
        New-EmptyFileIfNotExists $configPath $configContent
        
        Write-Success "ESTRUTURA CRIADA COM SUCESSO!"
        Write-Info "Total de diretorios criados: $($directories.Count)"
        Write-Info "Total de arquivos criados: $($files.Count + $emptyDirs.Count + 1)"
        Write-Info "Arquivo de configuracao: profile_settings_config.md"
        
        Write-Info "PROXIMOS PASSOS:"
        Write-Info "1. Copiar implementacoes completas dos artefatos"
        Write-Info "2. Atualizar navigation routes"
        Write-Info "3. Testar integracao"
        
    } catch {
        Write-Error "ERRO durante criacao da estrutura: $($_.Exception.Message)"
        throw
    }
}

# Validar parametros
if (-not (Test-Path $ProjectPath)) {
    Write-Error "Caminho do projeto nao encontrado: $ProjectPath"
    exit 1
}

# Executar funcao principal
try {
    Initialize-ProfileSettingsStructure -BasePath $ProjectPath
    Write-Success "Script executado com sucesso!"
} catch {
    Write-Error "Falha na execucao do script: $($_.Exception.Message)"
    exit 1
}

# Pausar para leitura (opcional)
if ($Host.UI.RawUI.KeyAvailable -eq $false) {
    Write-Info "Pressione qualquer tecla para continuar..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}