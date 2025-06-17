// Constants

// lib/utils/constants.dart - Constants

import 'package:unlock/models/item_model.dart';

class Constants {
  static final List<ItemModel> shopItems = [
    ItemModel(
      id: '1',
      name: 'xxxxxxxx',
      emoji: '🥣',
      cost: 15,
      type: 'xxxxx', // Tipo mais genérico
      effects: {'xxx': 15}, // ✅ Efeito estruturado
      category: 'xxxxxx',
    ),
  ];
}
