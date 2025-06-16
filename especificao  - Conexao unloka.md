 ESPECIFICAÇÃO COMPLETA - FLUXO DE CONEXÃO UNLOCK
🎯 CONCEITO GERAL
Sistema de matching baseado em afinidade real onde usuários devem "desbloquear" conexões através de testes de compatibilidade, garantindo conexões mais autênticas.


ESPECIFICACAO
 Riverpod  gerencia de estado 
 Firebase 
 sharedpreference
 flutter/dart
 
 Design :  deve ter animacoes proficinais e fluidas . 

🔄 FLUXO COMPLETO DE CONEXÃO
1. DESCOBERTA INICIAL
yamlTela: UnlockDiscoveryScreen
Estado: Usuários com codinomes fictícios que estejam online o sistema verifica os usuarios online e separa 3 para teste 
Informações Visíveis:
  - Codinome (ex: "Aventureiro23")
  - Idade
  - Interesses em comum (parciais)
  - Score de compatibilidade inicial (algoritmo básico)
  - Status: "🔒 Bloqueado"

Ações Disponíveis:
  - Ver perfil limitado
  - Iniciar teste de afinidade
  - Pular para próximo
2. TESTE DE AFINIDADE
yamlTela: AffinityTestScreen
Processo:
  - 5-10 perguntas baseadas em interesses comuns
  - Perguntas categorizadas (valores, lifestyle, objetivos)
  - Respostas múltipla escolha
  - Progresso visual
  - Timer opcional (pressão saudável)

Tipos de Pergunta:
  - Valores pessoais
  - Preferências de lifestyle  
  - Objetivos de relacionamento
  - Situações hipotéticas
  - Dealbreakers
3. CÁLCULO DE AFINIDADE
yamlAlgoritmo de Pontuação:
  - Respostas idênticas: +10 pontos
  - Respostas compatíveis: +5 pontos
  - Respostas neutras: 0 pontos
  - Respostas conflitantes: -5 pontos
  - Dealbreakers: -20 pontos

Score Final:
  - 0-40%: Não compatível
  - 41-60%: Compatibilidade baixa  
  - 61-75%: Boa compatibilidade
  - 76-85%: Ótima compatibilidade
  - 86-100%: Compatibilidade excepcional

Critério de Desbloqueio:
  - Mínimo 65% para desbloqueio
  - Ambos devem atingir score mínimo
4. RESULTADO DO TESTE
yamlSe Passou (≥65%):
  - 🎉 "Parabéns! Vocês têm ótima afinidade!"
  - Perfil desbloqueado
  - Nome real revelado
  - Fotos completas liberadas
  - Chat habilitado
  - Recompensas: XP + Coins

Se Não Passou (<65%):
  - 😔 "Afinidade insuficiente"
  - Perfil permanece bloqueado
  - Sem acesso ao chat
  - Opção de tentar com outros
  - Feedback construtivo
5. PERFIL DESBLOQUEADO
yamlTela: UnlockedProfileScreen
Informações Liberadas:
  - Nome real
  - Todas as fotos
  - Bio completa
  - Interesses detalhados
  - Redes sociais (opcional)
  - Badge de verificação
  
Status: "🔓 Desbloqueado"
Ações:
  - Iniciar conversa
  - Enviar super like
  - Compartilhar redes sociais
  - Agendar encontro
6. CHAT LIBERADO
yamlFuncionalidades:
  - Mensagens de texto
  - Emojis e GIFs
  - Compartilhamento de mídia
  - Mensagens que somem (opcional)
  - Status de leitura
  - Notificações push

Limitações Iniciais:
  - Máximo 50 mensagens/dia (incentivar encontro real)
  - Sem chamadas de vídeo inicialmente
  - Moderação de conteúdo

🎮 SISTEMA DE GAMIFICAÇÃO
RECOMPENSAS POR AÇÃO
yamlCompletar Teste:
  - XP: +25
  - Coins: +10

Desbloquear Perfil:
  - XP: +50  
  - Coins: +25
  - Gems: +1

Ser Desbloqueado:
  - XP: +30
  - Coins: +15

Primeira Conversa:
  - XP: +20
  - Coins: +10

Streak Diário:
  - 3 dias: +Bonus 50% XP
  - 7 dias: +25 Coins extras
  - 30 dias: +5 Gems extras
SISTEMA DE NÍVEIS
yamlLevel 1-5: Novato
  - 0-500 XP
  - 3 testes gratuitos/dia
  - Basic matchmaking

Level 6-15: Explorador  
  - 501-2000 XP
  - 5 testes/dia
  - Enhanced algorithm

Level 16-30: Expert
  - 2001-5000 XP
  - 8 testes/dia
  - Priority matching

Level 31+: Master
  - 5000+ XP
  - Unlimited tests
  - VIP features

🛒 SISTEMA DE LOJA
ITENS DISPONÍVEIS
yamlBoosts:
  - Super Like (50 coins): 3x chance desbloqueio
  - Boost Visibilidade (75 coins): Aparecer mais
  - Reset Chance (100 coins): Segunda tentativa no teste

Premium Features:
  - Ver quem te desbloqueou (200 coins)
  - Filtros avançados (150 coins)
  - Testes ilimitados (5 gems)

Cosméticos:
  - Badges especiais (25-100 coins)
  - Frames de perfil (50 coins)
  - Emojis exclusivos (30 coins)

🔧 IMPLEMENTAÇÃO TÉCNICA
ESTRUTURA DE DADOS
yamlUnlockMatch:
  - id, userId, otherUserId
  - compatibilityScore
  - status (pending, unlocked, rejected)
  - testResults, createdAt

AffinityTest:
  - questions[], userAnswers[], otherAnswers[]
  - score, passed, completedAt
  - categories, feedbackPoints[]

UnlockStats:
  - totalTests, successRate, streak
  - xpEarned, achievements[]
  - categoryPerformance{}
FLUXO DE ESTADOS
yaml1. Discovery → TestPending
2. TestPending → TestInProgress  
3. TestInProgress → TestCompleted
4. TestCompleted → Unlocked/Rejected
5. Unlocked → ChatEnabled
6. ChatEnabled → ConnectionActive
APIS NECESSÁRIAS
yamlMatching:
  - GET /api/discover (filtros, paginação)
  - POST /api/start-test (matchId)
  - POST /api/submit-answer (questionId, answerId)
  - POST /api/complete-test (testId)

Profile:
  - GET /api/profile/locked (info limitada)
  - GET /api/profile/unlocked (info completa)
  - PUT /api/profile/update

Chat:
  - WebSocket connection
  - POST /api/messages/send
  - GET /api/messages/history

📱 TELAS NECESSÁRIAS
PRINCIPAIS

UnlockDiscoveryScreen - Carrossel de perfis bloqueados
AffinityTestScreen - Quiz interativo
TestResultScreen - Resultado com animações
UnlockedProfileScreen - Perfil completo liberado
ChatScreen - Conversa pós-desbloqueio

SECUNDÁRIAS

UnlockStatsScreen - Estatísticas pessoais
AchievementsScreen - Conquistas desbloqueadas
ShopScreen - Loja de itens
SettingsScreen - Preferências de matching


🚀 ROADMAP IMPLEMENTAÇÃO
FASE 1: Core Matching (3 dias)

 UnlockDiscoveryScreen funcional
 Sistema básico de compatibilidade
 Algoritmo de matching inicial

FASE 2: Testes de Afinidade (3 dias)

 AffinityTestScreen completa
 Banco de perguntas dinâmico
 Cálculo de pontuação

FASE 3: Sistema de Desbloqueio (2 dias)

 Lógica de unlock
 Estados de perfil
 Transições animadas

FASE 4: Chat e Gamificação (2 dias)

 Chat em tempo real
 Sistema de XP/Coins
 Achievements básicos

TOTAL: ~10 dias de desenvolvimento

✅ CRITÉRIOS DE SUCESSO

Funcional: Fluxo completo sem erros
Performático: Carregamento <2s
Intuitivo: Usuário entende sem tutorial
Envolvente: Sistema de recompensas efetivo
Escalável: Suporta milhares de usuários
