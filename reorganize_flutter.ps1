# Lista de arquivos a serem criados
$placeholderFiles = @(
    "lib/config/app_constants.dart",
    "lib/models/connection_model.dart",
    "lib/models/message_model.dart", 
    "lib/models/mission_model.dart",
    "lib/models/game_model.dart",
    "lib/services/firestore_service.dart",
    "lib/services/storage_service.dart",
    "lib/providers/chat_provider.dart",
    "lib/providers/matching_provider.dart",
    "lib/providers/mission_provider.dart",
    "lib/providers/shop_provider.dart",
    "lib/providers/game_provider.dart",
    "lib/widgets/common/custom_button.dart",
    "lib/widgets/common/custom_text_field.dart",
    "lib/widgets/common/loading_widget.dart",
    "lib/widgets/animated/fade_in_widget.dart",
    "lib/widgets/animated/bounce_widget.dart",
    "lib/utils/validators.dart",
    "lib/utils/formatters.dart",
    "lib/utils/extensions.dart",
    "lib/data/local_storage.dart"
)

# Diretório base (pasta do script ou outro diretório)
$basePath = Get-Location

foreach ($filePath in $placeholderFiles) {
    $fullPath = Join-Path -Path $basePath -ChildPath $filePath

    # Criar diretórios necessários
    $directory = Split-Path -Path $fullPath -Parent
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }

    # Criar arquivo vazio apenas se não existir
    if (-not (Test-Path -Path $fullPath)) {
        New-Item -ItemType File -Path $fullPath | Out-Null
        Write-Host "Criado: $fullPath"
    } else {
        Write-Host "Já existe: $fullPath"
    }
}

Write-Host "`nTodos os arquivos foram criados (ou verificados)." -ForegroundColor Green