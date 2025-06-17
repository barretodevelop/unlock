1. Visão Geral do Projeto
   Desenvolvimento de um aplicativo de rede social gamificada que permite aos usuários conectar-se de forma mais autêntica através de um processo de "desbloqueio" gradual de informações pessoais, incentivado por missões, minijogos e recompensas. O foco é na privacidade inicial e na construção de conexões reais, com mecanismos robustos de segurança e moderação, incluindo verificação de idade e controle de conteúdo.

2. Escopo Detalhado das Fases e Tarefas
   Recursos Chave: Equipe de Desenvolvimento (Flutter), Designer UX/UI, Especialista em Backend (Firebase), QA Tester, Gerente de Produto/Projeto, Especialista em Moderacao/Segurança.

Fase 1 – Estrutura Base (Estimativa: 2-3 Semanas)

Objetivo: Estabelecer a base técnica e arquitetural do projeto.
Tarefas:
1.1. Configuração do Projeto Flutter:
Confirmar suporte multiplataforma (iOS, Android).  ja ok
Configurar ambiente de desenvolvimento (IDE, SDKs). ja ok
Configurar controle de versão (Git) e repositório. ja ok

1.2. Integração Firebase:
Configurar projeto Firebase (Auth, Firestore). ja ok
Implementar auth_provider.dart para autenticação Google Sign-In. ja ok
Configurar regras iniciais de segurança do Firestore (regra por profileUnlocked e baseadas em userId).
Implementar testes unitários para regras de segurança do Firestore.  todos os tests sera gerada no final do projeto

1.3. Gerenciamento de Estado (Riverpod):
Integrar Riverpod ao projeto.
Definir estrutura inicial de providers para autenticação e dados do usuário. ja ok disponivel nas pasta lib/providers/auth_provider.dart ,porem pode ser corrigida

1.4. Definição da Arquitetura (Clean Code/Modular):
Definir estrutura de pastas: clean code light
comentario basico em cada method e implementar sistema de log para em debug para os principais fluxos
todo o codigo do projeto deve ser otimado para ser eficiente e nao verboso.
sempre que puder user widget para modularizar e facilitar a manutencao e atualizacao


1.5. Configurações de Ambiente:
Configurar ambientes de desenvolvimento, staging e produção no Firebase.  usar .env
gerar um script powersheel que gere a estrutura de pastas iniciais.
COnfigurar um arquivo de ota bem definido e seguro.


Fase 2 – Login e Perfil Anônimo (Estimativa: 4-6 Semanas)

Objetivo: Permitir o cadastro e login de usuários, com criação de perfil anônimo e coleta inicial de dados.
Tarefas:
2.0 sistema deve comecar com uma tela de SplashScreen bem definida que valida a authenticacao e chama a Rota de navegacao condizente 

2.1. Implementação de Login com Google:
Desenvolver UI para tela de login.
Integrar Google Sign-In via Firebase Auth.

2.2. Verificação de Idade:
Desenvolver UI para coleta da data de nascimento.
Implementar lógica de validação de idade mínima.
Definir lógica para usuários menores de idade (range específico).

2.3. Onboarding Interativo:
Projetar e desenvolver telas de onboarding para coleta de: obs nessa tela ja deve ser exibida  uma app bar com as informações reais do usuario feita no login e exibir tambem os dados degame do usuario , pois podera comprar avatar especifico para uso
Avatar e nome de anônimo (ex: emoji, ícone).
Interesses (sistema de tags/categorias predefinidas).
Objetivo (amizade, namoro...).
Nível de conexão. pode ser um slide com range de 1 a 10 quanto maior mais exigente sera a conexao 
Implementar feedback visual e UX para o onboarding.

2.4. Criação do Perfil no Firestore:
Estruturar modelo de dados User no Firestore (incluindo as informações coletada).
Implementar lógica para salvar perfil inicial no Firestore.

2.5. Exibição de Perfil Anônimo:
Desenvolver UI para exibição do perfil público limitado (avatar, interesses, objetivo).
Garantir que nome e foto reais sejam visíveis apenas para conexões confirmadas.


Fase 3 – Home e Missões (Estimativa: 3-4 Semanas)

Objetivo: Criar a tela inicial e o sistema básico de gamificação (moedas, XP, missões).
Tarefas:

3.1. Desenvolvimento da Tela Home:
Projetar e desenvolver UI para a tela inicial (layout, navegação).
Exibir indicadores de Coins, Gems, XP.
Integrar botão "Localizar conexões".

3.2. Sistema de Missões:
Desenvolver modelo de dados para missões (diárias, semanais).
Implementar lógica para atribuição e acompanhamento de missões.
Desenvolver UI para exibir missões e seu progresso.

3.3. Sistema de Recompensas:
Implementar lógica para ganho de XP, moedas e gemas ao completar missões.
Atualizar dados do usuário no Firestore.
3.4. Nivelamento e Progresso:
Desenvolver lógica de nivelamento com base no XP.
Desenvolver UI para exibir nível e recompensas por nível.




Fase 4 – Matching e Conexões (Estimativa: 4-5 Semanas)

Objetivo: Implementar a lógica de busca e o processo inicial de convite de conexão.
Tarefas:
4.1. Algoritmo de Busca de Usuários:
Implementar busca por usuários online com interesses compatíveis.
Aplicar filtragem por interesses e idade (respeitando o range para menores).
Priorizar aleatoriedade e interesses.
4.2. Localização (Opcional):
Implementar solicitação de permissão para localização.
Armazenar cidade ou região aproximada no Firestore (com privacidade).
Integrar filtro de localização no matching (prioridade para proximidade).
4.3. Exibição de Cards Anônimos:
Desenvolver UI para exibir até 3 cards de usuários por vez (anonimizados: avatar, interesses, objetivo).
Implementar funções de "aceitar" e "ignorar" card.
4.4. Criação e Gestão de Convites:
Implementar lógica para criar convite de conexão no Firestore ao aceitar um card.
Desenvolver UI para usuário B receber e aceitar/recusar convite.
Desenvolver uma seção para o usuário gerenciar convites (enviados e recebidos).
Fase 5 – Teste de Compatibilidade (Estimativa: 3-4 Semanas)

Objetivo: Implementar o teste de compatibilidade baseado em perguntas.
Tarefas:
5.1. Banco de Perguntas:
Criar estrutura de dados para perguntas ( Firestore collection).
Desenvolver lógica para gerar perguntas com base nos interesses em comum.
5.2. UI e Fluxo do Teste:
Desenvolver UI para o teste de perguntas (interface intuitiva, timer).
Implementar sincronização das respostas via Firestore.
5.3. Algoritmo de Compatibilidade:
Desenvolver algoritmo local para comparar respostas e calcular compatibilidade.
Definir limite de 70% para prosseguir ao minijogo.
Fase 6 – Minijogo de Conexão (Estimativa: 4-5 Semanas)

Objetivo: Implementar o minijogo colaborativo para desbloqueio de perfil.
Tarefas:
6.1. Desenvolvimento do Minijogo:
Desenvolver UI e lógica para jogo tipo memória com cartas pareadas.
Implementar turnos alternados e timer.
Adicionar feedback visual e sonoro.
6.2. Sincronização via Firestore:
Implementar sincronização mínima via Firestore (jogador_atual, cartas_viradas).
6.3. Lógica de Pontuação e Desbloqueio:
Implementar lógica para pontuação mínima.
Se pontuação atingida, acionar desbloqueio do perfil completo.
Oferecer opção de gastar gemas para tentar novamente (ou outras alternativas como assistir anúncio/esperar).
Fase 7 – Sistema de Conexões e Visibilidade (Estimativa: 2-3 Semanas)

Objetivo: Gerenciar as conexões e a visibilidade das informações do perfil.
Tarefas:
7.1. Gerenciamento de Conexões:
Desenvolver lógica para conexões bidirecionais.
Implementar funcionalidade de "desfazer conexão" e "bloquear" usuário.
Atualizar profileUnlocked = true entre os usuários conectados no Firestore.
7.2. Lista de Conexões:
Desenvolver UI para exibir lista de conexões do usuário.
7.3. Visibilidade do Perfil:
Garantir que perfis de não-conexões mostrem apenas dados públicos limitados.
Exibir nome real, foto e customização completa apenas após conexão confirmada.
Fase 8 – Loja e Personalização de Perfil (Estimativa: 3-4 Semanas)

Objetivo: Implementar a loja de itens e permitir a personalização do perfil.
Tarefas:
8.1. Desenvolvimento da Loja:
Projetar e desenvolver UI para a loja (categorias, itens, preços).
Estruturar modelo de dados para itens (Firestore).
Implementar compra com moedas ou gemas, atualizando inventário do usuário.
8.2. Personalização do Perfil:
Implementar lógica para aplicar skins de avatar, molduras, badges e itens decorativos.
Desenvolver UI para a tela de personalização.
Garantir que itens aplicados afetem o perfil público.
Fase 9 – Integração com Localização (Estimativa: 1-2 Semanas)

Objetivo: Adicionar funcionalidade de localização opcional para matching.
Tarefas:
9.1. Permissão de Localização:
Integrar solicitação de permissão de localização do sistema.
9.2. Armazenamento Seguro da Localização:
Armazenar apenas cidade ou região aproximada no Firestore (preservando privacidade).
9.3. Filtro de Matching por Localização:
Integrar prioridade de matching para usuários da mesma região (quando a localização estiver ativa).
Fase 9.5 – Moderação e Segurança (Estimativa: 4-6 Semanas)

Objetivo: Garantir um ambiente seguro e livre de conteúdo impróprio.
Tarefas:
9.5.1. Filtro de Conteúdo de Texto:
Implementar bibliotecas ou APIs de terceiros para detecção de linguagem ofensiva/imprópria em campos de texto livre (ex: descrições, chat futuro).
9.5.2. Filtro de Imagens/Avatares:
Integrar serviço de moderação de imagens (ex: Google Cloud Vision API, Azure Content Moderator) para verificar uploads de fotos de perfil.
Automatizar o bloqueio ou revisão manual de imagens inapropriadas.
9.5.3. Sistema de Denúncias:
Desenvolver UI para denúncia de usuários/conteúdo (motivos, evidências).
Implementar lógica para registrar denúncias no Firestore.
9.5.4. Painel de Moderação:
Desenvolver um painel administrativo (fora do app) para revisão de denúncias e gerenciamento de usuários (avisos, suspensões, banimentos).
9.5.5. Diretrizes da Comunidade:
Redigir e implementar exibição clara das diretrizes da comunidade no app.
9.5.6. Restrições para Menores (Reforço):
Garantir que as regras de segurança e o algoritmo de matching apliquem estritamente as restrições de idade para menores (ex: proibição de chat com adultos, visibilidade restrita).
Fase 10 – Otimizações e Redução de Custos (Contínua, Intensificada no Final)

Objetivo: Otimizar performance e reduzir custos operacionais.
Tarefas:
10.1. Otimização de Leitura/Escrita Firestore:
Revisar todas as operações, utilizando merge: true em updates.
Garantir sincronização pontual (não contínua) onde possível (ex: minijogo).
Analisar e refatorar dados fragmentados em subcoleções.
10.2. Minimização de Cloud Functions:
Revisar lógica para garantir que cálculos de compatibilidade e outras lógicas sejam 100% locais (se possível).
Avaliar a necessidade de Cloud Functions para validação de compras ou anti-fraude, se aplicável.
10.3. Otimização de Queries Firestore:
Analisar e otimizar queries, evitando array-contains-any múltiplos.
Criar índices Firestore compostos e simples conforme a necessidade.
Utilizar limit() para listas paginadas.
Utilizar Firebase Emulators para teste e otimização de queries.
10.4. App Leve:
Analisar e modularizar recursos pesados (animações, imagens).
Remover plugins desnecessários.
Garantir layout responsivo e reuso de componentes leves.
Fase 11 – Preparação para Monetização (Estimativa: 2-3 Semanas)

Objetivo: Integrar sistemas de compra e definir planos de monetização.
Tarefas:
11.1. Integração In-App Purchase:
Configurar in_app_purchase para Play/App Store.
Registrar pacotes de gemas, skins raras e funções exclusivas nas lojas.
11.2. Definição e Implementação de Plano Premium:
Definir benefícios do plano Premium (filtros adicionais, repetição de testes sem gemas, personalização exclusiva).
Desenvolver UI para apresentação e compra do plano Premium.
Implementar lógica para ativar benefícios Premium para assinantes.
Considerar período de teste gratuito para Premium.
11.3. Estratégias de Preço:
Definir estratégias de precificação para itens e assinaturas.
Fase 12 – Finalização e Publicação (Estimativa: 3-4 Semanas)

Objetivo: Polimento, testes finais e lançamento do aplicativo.
Tarefas:
12.1. Polimento Visual e UX:
Integrar flutter_animate para animações e transições.
Implementar tema escuro/claro.
Desenvolver SplashScreen animada.
Refinar a usabilidade e a experiência do usuário em todas as telas.
12.2. Testes Completos:
Realizar testes de unidade, widget, integração e performance.
Realizar testes de ponta a ponta (E2E) para fluxos críticos.
Testes de segurança (pen tests básicos, revisão de regras).
Testes de compatibilidade em diversos dispositivos e versões de OS.
12.3. Documentação:
Preparar documentação para usuários (FAQs, guia de uso).
Documentar APIs internas e externas para manutenção futura.
12.4. Preparação para Lançamento:
Criar textos, screenshots e vídeo promocional para as lojas.
Configurar Firebase Crashlytics e outras ferramentas de monitoramento.
Preparar planos de marketing e PR.
12.5. Publicação nas Lojas:
Submeter o aplicativo para revisão na Google Play Store e Apple App Store.
Monitorar o processo de aprovação. 3. Gestão de Riscos (Exemplos)
Risco: Dificuldade em atrair usuários iniciais.
Mitigação: Estratégia de marketing pré-lançamento, parcerias com influenciadores, programa de beta testers.
Risco: Problemas de desempenho com o Firebase em escala.
Mitigação: Monitoramento constante, otimização de queries, possível migração para soluções mais robustas para funcionalidades específicas se necessário (ex: WebSockets para chat em tempo real, se Firebase não for suficiente).
Risco: Falha na detecção de conteúdo impróprio.
Mitigação: Treinamento contínuo dos modelos de IA, sistema robusto de denúncias, equipe de moderação dedicada.
Risco: Dificuldade em monetizar o app.
Mitigação: Testes A/B de precificação, pesquisa de usuário sobre a disposição para pagar, ajustes nas ofertas Premium.
Risco: Questões legais com privacidade de dados de menores.
Mitigação: Consulta a advogados especializados em proteção de dados (LGPD no Brasil, GDPR na Europa, COPPA nos EUA), implementação de consentimentos claros, política de privacidade transparente. 4. Métricas de Sucesso (Exemplos)
Usuários Ativos Mensais (MAU) e Diários (DAU): Indica o engajamento geral.
Taxa de Conexão: % de convites de conexão aceitos.
Taxa de Desbloqueio de Perfil: % de usuários que completam o minijogo e desbloqueiam perfis.
Retenção de Usuários: % de usuários que retornam após 7, 30, 90 dias.
Receita por Usuário (ARPU): Para avaliar a monetização.
Uso de Recursos (Firebase): Monitorar custos e otimizações.
Índice de Denúncias: Para avaliar a eficácia da moderação.
Este Plano de Execução oferece uma visão muito mais detalhada do "como" cada fase do roadmap será implementada, com tarefas específicas e considerações importantes para segurança e moderação. Lembre-se que um plano de execução é um documento vivo e deve ser atualizado e refinado à medida que o projeto avança.
