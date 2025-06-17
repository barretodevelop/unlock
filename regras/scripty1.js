// // firestore.rules - Regras de Segurança para Unlock App
// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
    
//     // ===== USUÁRIOS =====
//     match /users/{userId} {
//       // Usuários podem ler e escrever apenas seus próprios dados
//       allow read, write: if request.auth != null && request.auth.uid == userId;
      
//       // Permitir leitura de perfil público limitado para outros usuários autenticados
//       allow read: if request.auth != null && 
//                  request.auth.uid != userId &&
//                  // Só campos públicos são acessíveis
//                  resource.data.keys().hasAny(['codinome', 'anonAvatar', 'interesses', 'relationshipInterest']);
      
//       // Subcoleção de conexões do usuário
//       match /connections/{connectionId} {
//         allow read, write: if request.auth != null && request.auth.uid == userId;
//       }
      
//       // Subcoleção de missões do usuário
//       match /missions/{missionId} {
//         allow read, write: if request.auth != null && request.auth.uid == userId;
//       }
      
//       // Subcoleção de inventário do usuário
//       match /inventory/{itemId} {
//         allow read, write: if request.auth != null && request.auth.uid == userId;
//       }
//     }
    
//     // ===== CONEXÕES =====
//     match /connections/{connectionId} {
//       // Usuários podem ver conexões onde participam
//       allow read: if request.auth != null && 
//                  (resource.data.user1 == request.auth.uid || 
//                   resource.data.user2 == request.auth.uid);
      
//       // Apenas usuários podem criar conexões onde são um dos participantes
//       allow create: if request.auth != null && 
//                    (request.resource.data.user1 == request.auth.uid || 
//                     request.resource.data.user2 == request.auth.uid);
      
//       // Apenas participantes podem atualizar conexões
//       allow update: if request.auth != null && 
//                    (resource.data.user1 == request.auth.uid || 
//                     resource.data.user2 == request.auth.uid);
      
//       // Apenas participantes podem deletar conexões
//       allow delete: if request.auth != null && 
//                    (resource.data.user1 == request.auth.uid || 
//                     resource.data.user2 == request.auth.uid);
//     }
    
//     // ===== CONVITES DE CONEXÃO =====
//     match /connection_invites/{inviteId} {
//       // Usuário que enviou ou recebeu pode ver o convite
//       allow read: if request.auth != null && 
//                  (resource.data.senderId == request.auth.uid || 
//                   resource.data.receiverId == request.auth.uid);
      
//       // Apenas usuário autenticado pode criar convite onde é o sender
//       allow create: if request.auth != null && 
//                    request.resource.data.senderId == request.auth.uid &&
//                    request.resource.data.senderId != request.resource.data.receiverId;
      
//       // Apenas receiver pode aceitar/recusar (update status)
//       allow update: if request.auth != null && 
//                    resource.data.receiverId == request.auth.uid &&
//                    request.resource.data.keys().hasAny(['status', 'respondedAt']);
      
//       // Sender pode cancelar convite
//       allow delete: if request.auth != null && 
//                    resource.data.senderId == request.auth.uid;
//     }
    
//     // ===== TESTES DE COMPATIBILIDADE =====
//     match /compatibility_tests/{testId} {
//       // Apenas participantes podem ver o teste
//       allow read: if request.auth != null && 
//                  (resource.data.user1 == request.auth.uid || 
//                   resource.data.user2 == request.auth.uid);
      
//       // Apenas um dos usuários pode criar o teste
//       allow create: if request.auth != null && 
//                    (request.resource.data.user1 == request.auth.uid || 
//                     request.resource.data.user2 == request.auth.uid);
      
//       // Apenas participantes podem atualizar (responder perguntas)
//       allow update: if request.auth != null && 
//                    (resource.data.user1 == request.auth.uid || 
//                     resource.data.user2 == request.auth.uid);
//     }
    
//     // ===== MINIJOGOS =====
//     match /minigames/{gameId} {
//       // Apenas participantes podem ver o jogo
//       allow read: if request.auth != null && 
//                  (resource.data.player1 == request.auth.uid || 
//                   resource.data.player2 == request.auth.uid);
      
//       // Apenas um dos jogadores pode criar o jogo
//       allow create: if request.auth != null && 
//                    (request.resource.data.player1 == request.auth.uid || 
//                     request.resource.data.player2 == request.auth.uid);
      
//       // Apenas participantes podem atualizar (fazer jogadas)
//       allow update: if request.auth != null && 
//                    (resource.data.player1 == request.auth.uid || 
//                     resource.data.player2 == request.auth.uid);
//     }
    
//     // ===== LOJA DE ITENS (READ-ONLY) =====
//     match /shop_items/{itemId} {
//       // Todos usuários autenticados podem ver itens da loja
//       allow read: if request.auth != null;
//       // Apenas admins podem modificar (será implementado posteriormente)
//     }
    
//     // ===== DENÚNCIAS =====
//     match /reports/{reportId} {
//       // Apenas o usuário que fez a denúncia pode ver
//       allow read: if request.auth != null && 
//                  resource.data.reporterId == request.auth.uid;
      
//       // Qualquer usuário autenticado pode criar denúncia
//       allow create: if request.auth != null && 
//                    request.resource.data.reporterId == request.auth.uid;
//     }
    
//     // ===== LOGS DE SEGURANÇA =====
//     match /security_logs/{logId} {
//       // Apenas sistema pode escrever logs (via Cloud Functions)
//       allow read, write: if false; // Bloqueia acesso direto do cliente
//     }
    
//     // ===== FUNÇÕES AUXILIARES =====
    
//     // Verifica se usuário é menor de idade
//     function isMinor(userId) {
//       return get(/databases/$(database)/documents/users/$(userId)).data.isMinor == true;
//     }
    
//     // Verifica se usuário completou onboarding
//     function hasCompletedOnboarding(userId) {
//       return get(/databases/$(database)/documents/users/$(userId)).data.onboardingCompleted == true;
//     }
    
//     // Verifica se perfil foi desbloqueado entre dois usuários
//     function isProfileUnlocked(userId1, userId2) {
//       return exists(/databases/$(database)/documents/connections/$(userId1 + '_' + userId2)) ||
//              exists(/databases/$(database)/documents/connections/$(userId2 + '_' + userId1));
//     }
    
//     // ===== RESTRIÇÕES PARA MENORES =====
//     // Menores só podem interagir com outros menores em faixa etária similar
//     match /age_restricted_interactions/{interactionId} {
//       allow read, write: if request.auth != null && 
//                         isMinor(request.auth.uid) && 
//                         hasCompletedOnboarding(request.auth.uid);
//     }
    
//     // ===== PREVENÇÃO DE SPAM =====
//     // Limitar criação de convites (máximo 10 por dia)
//     match /rate_limits/{userId} {
//       allow read, write: if request.auth != null && request.auth.uid == userId;
//     }
//   }
// }