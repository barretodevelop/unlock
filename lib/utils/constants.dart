// Constants

// lib/utils/constants.dart - Constants

import 'package:unlock/models/item_model.dart';

class Constants {
  static final List<ItemModel> shopItems = [
    ItemModel(
      id: '1',
      name: 'Ração Básica',
      emoji: '🥣',
      cost: 15,
      type: 'consumable', // Tipo mais genérico
      effects: {'hunger': 15}, // ✅ Efeito estruturado
      category: 'comida',
    ),
    ItemModel(
      id: '2',
      name: 'Comida Premium',
      emoji: '🥩',
      cost: 30,
      type: 'consumable',
      effects: {'hunger': 25, 'happiness': 10}, // ✅ Efeito estruturado
      category: 'comida',
    ),
    ItemModel(
      id: '3',
      name: 'Unlockisco Especial',
      emoji: '🦴',
      cost: 20,
      type: 'consumable',
      effects: {'happiness': 20}, // ✅ Efeito estruturado
      category: 'comida',
    ),
    ItemModel(
      id: '4',
      name: 'Bola',
      emoji: '⚽',
      cost: 25,
      type: 'reusable', // Tipo mais genérico
      effects: {
        'happiness': 20,
        'energy': -5,
      }, // Brincar gasta energia, aumenta felicidade
      category: 'brinquedo',
    ),
    ItemModel(
      id: '5',
      name: 'Corda',
      emoji: '🧸',
      cost: 35,
      type: 'reusable',
      effects: {'happiness': 25, 'energy': -10}, // ✅ Efeito estruturado
      category: 'brinquedo',
    ),
    ItemModel(
      id: '6',
      name: 'Vitamina',
      emoji: '💊',
      cost: 40,
      type: 'consumable',
      effects: {'health': 25}, // ✅ Efeito estruturado
      category: 'medicina',
    ),
    ItemModel(
      id: '7',
      name: 'Poção Cura',
      emoji: '🧪',
      cost: 60,
      type: 'consumable',
      effects: {'health': 40, 'energy': 10}, // ✅ Efeito estruturado
      category: 'medicina',
    ),
    ItemModel(
      id: '8',
      name: 'Chapéu Mágico',
      emoji: '🎩',
      cost: 100,
      type: 'wearable', // Tipo mais genérico
      effects: {'happiness': 5, 'energy': 5}, // Exemplo, pode ser mais complexo
      category: 'acessório',
    ),
    ItemModel(
      id: '9',
      name: 'Coleira Dourada',
      emoji: '🏆',
      cost: 80,
      type: 'wearable',
      effects: {'happiness': 10}, // ✅ Efeito estruturado
      category: 'acessório',
    ),
    ItemModel(
      id: '10',
      name: 'Laço Rosa',
      emoji: '🎀',
      cost: 50,
      type: 'wearable',
      effects: {'happiness': 15}, // ✅ Efeito estruturado
      category: 'acessório',
    ),
    ItemModel(
      id: '11',
      name: 'Óculos Cool',
      emoji: '🕶️',
      cost: 70,
      type: 'wearable',
      effects: {'energy': 10, 'happiness': 5}, // ✅ Efeito estruturado
      category: 'acessório',
    ),
    ItemModel(
      id: '12',
      name: 'Coroa Real',
      emoji: '👑',
      cost: 150,
      type: 'wearable',
      effects: {'happiness': 10, 'health': 5, 'energy': 5}, // Exemplo
      category: 'acessório',
    ),
    ItemModel(
      id: '13',
      name: 'Cachecol',
      emoji: '🧣',
      cost: 60,
      type: 'wearable',
      effects: {'health': 10}, // ✅ Efeito estruturado
      category: 'acessório',
    ),
  ];

  // static final List<MissionModel> defaultMissions = [
  //   MissionModel(
  //       id: 1,
  //       title: 'Alimentar 3 vezes',
  //       desc: 'Alimente seu Unlock 3 vezes hoje',
  //       reward: 30,
  //       progress: 0,
  //       max: 3),
  //   MissionModel(
  //       id: 2,
  //       title: 'Brincar 5 vezes',
  //       desc: 'Brinque com seu Unlock 5 vezes',
  //       reward: 50,
  //       progress: 0,
  //       max: 5),
  //   MissionModel(
  //       id: 3,
  //       title: 'Cuidar 10 vezes',
  //       desc: 'Cuide do seu Unlock 10 vezes',
  //       reward: 40,
  //       progress: 0,
  //       max: 10),
  //   MissionModel(
  //       id: 4,
  //       title: 'Usar 5 itens',
  //       desc: 'Use 5 itens do inventário',
  //       reward: 60,
  //       progress: 0,
  //       max: 5),
  //   MissionModel(
  //       id: 5,
  //       title: 'Gerar Unlock único',
  //       desc: 'Gere seu primeiro Unlock único',
  //       reward: 200,
  //       progress: 0,
  //       max: 1),
  //   MissionModel(
  //       id: 6,
  //       title: 'Alcançar Nível 5',
  //       desc: 'Evolua seu Unlock até o nível 5',
  //       reward: 100,
  //       progress: 1,
  //       max: 5),
  // ];
}
