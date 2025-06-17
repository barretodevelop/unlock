#  Arquitetura do Projeto Unlock

## PrincÃ­pios
- **Clean Architecture**: SeparaÃ§Ã£o clara de responsabilidades
- **Feature-Based**: OrganizaÃ§Ã£o por funcionalidades
- **Provider Pattern**: Gerenciamento de estado com Riverpod
- **Single Responsibility**: Cada arquivo tem uma responsabilidade especÃ­fica

## Estrutura de Pastas

### /lib/core/
ConfiguraÃ§Ãµes centrais e utilitÃ¡rios compartilhados por todo o app.

### /lib/features/
Funcionalidades organizadas em mÃ³dulos independentes.

### /lib/shared/
Componentes reutilizÃ¡veis entre diferentes features.

### /lib/services/
ServiÃ§os globais (Firebase, APIs, Cache, etc.).

## Fluxo de Dados
User Interaction â†’ Widget â†’ Provider â†’ Service â†’ Backend â†’ Provider â†’ Widget

## ConvenÃ§Ãµes de Nomenclatura
- Arquivos: snake_case.dart
- Classes: PascalCase
- VariÃ¡veis: camelCase
- Constantes: UPPER_SNAKE_CASE
