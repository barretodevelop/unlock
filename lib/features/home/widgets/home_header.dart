// lib/features/home/widgets/home_header.dart - CORRIGIDO PARA EVITAR OVERFLOW
import 'package:flutter/material.dart';
import 'package:unlock/models/user_model.dart';

class HomeHeader extends StatelessWidget {
  final UserModel user;

  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ CORRIGIDO: Usar height flexível baseada no conteúdo
      constraints: const BoxConstraints(
        minHeight: 220, // Altura mínima
        maxHeight: 300, // Altura máxima
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            60,
            24,
            16,
          ), // ✅ AJUSTADO: Menos padding vertical
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ CORRIGIDO: Usar Flexible para permitir expansão
              Flexible(flex: 3, child: _buildUserInfo(context)),

              // ✅ CORRIGIDO: Espaçador flexível
              const Flexible(flex: 1, child: SizedBox(height: 16)),

              // ✅ CORRIGIDO: Progress bar sem altura fixa
              _buildLevelProgress(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Construir informações do usuário
  Widget _buildUserInfo(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // ✅ AJUSTADO: Alinhamento
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ✅ ADICIONADO: Tamanho mínimo
            children: [
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),

              // ✅ CORRIGIDO: Usar Flexible para texto longo
              Flexible(
                child: Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2, // ✅ ADICIONADO: Limitar linhas
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Nível ${user.level} • ${_formatXP(user.xp)} XP',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Avatar do usuário
        // UserAvatar(
        //   imageUrl: user.avatar.startsWith('http') ? user.avatar : null,
        //   fallbackText: user.avatar.startsWith('http') ? null : user.avatar,
        //   radius: 32, // ✅ REDUZIDO: Menor para economizar espaço
        // ),
      ],
    );
  }

  /// Construir barra de progresso do nível
  Widget _buildLevelProgress(BuildContext context) {
    final currentLevelXP = user.xp % 1000; // Assumindo 1000 XP por nível
    final progress = currentLevelXP / 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ ADICIONADO: Tamanho mínimo
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso do Nível',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              '$currentLevelXP / 1000 XP',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// Obter saudação baseada na hora
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Bom dia!';
    } else if (hour < 18) {
      return 'Boa tarde!';
    } else {
      return 'Boa noite!';
    }
  }

  /// Formatar XP com sufixo
  String _formatXP(int xp) {
    if (xp >= 1000000) {
      return '${(xp / 1000000).toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }
}
