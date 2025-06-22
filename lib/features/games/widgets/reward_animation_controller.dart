// lib/features/games/widgets/reward_animation_controller.dart

import 'package:flutter/foundation.dart';

/// Armazena os valores a serem exibidos na animação de recompensa.
class RewardAnimationValues {
  final int xp;
  final int coins;
  final int gems;

  RewardAnimationValues({this.xp = 0, this.coins = 0, this.gems = 0});
}

/// Controlador para disparar a animação de recompensa a partir de um widget pai.
class RewardAnimationController {
  late Function(RewardAnimationValues) _show;

  void show(RewardAnimationValues values) {
    _show(values);
  }

  // Método interno para ser usado pelo RewardGainOverlay
  void register(Function(RewardAnimationValues) onShow) {
    _show = onShow;
  }
}
