class ItemModel {
  final String id; // ✅ Alterado de int para String
  final int cost;
  final String name, emoji, type, category;
  final Map<String, int>
  effects; // ✅ Alterado de String effect para Map<String, int> effects
  ItemModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.type,
    required this.effects,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'cost': cost,
    'type': type,
    'effects': effects, // ✅ Usar o novo campo
    'category': category,
  };

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
    id: json['id'] as String, // ✅ Cast para String
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    cost: json['cost'] as int,
    type: json['type'] as String,
    effects: Map<String, int>.from(json['effects'] ?? {}), // ✅ Ler o novo campo
    category: json['category'] as String,
  );

  ItemModel copyWith({
    String? id, // ✅ Alterado de int? para String?
    String? name,
    String? emoji,
    int? cost,
    String? type,
    Map<String, int>? effects, // ✅ Adicionar effects ao copyWith
    String? category,
  }) => ItemModel(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    cost: cost ?? this.cost,
    type: type ?? this.type,
    effects: effects ?? this.effects,
    category: category ?? this.category,
  );
}
