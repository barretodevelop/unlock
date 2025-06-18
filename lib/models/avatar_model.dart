// lib/models/avatar_model.dart

class AvatarModel {
  final String id;
  final String emoji;
  final String name;
  final bool isPremium;
  final int? cost;
  final String? currency; // 'coins' ou 'gems'
  final String category;

  const AvatarModel({
    required this.id,
    required this.emoji,
    required this.name,
    this.isPremium = false,
    this.cost,
    this.currency,
    required this.category,
  });

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    return AvatarModel(
      id: json['id'],
      emoji: json['emoji'],
      name: json['name'],
      isPremium: json['isPremium'] ?? false,
      cost: json['cost'],
      currency: json['currency'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
      'isPremium': isPremium,
      'cost': cost,
      'currency': currency,
      'category': category,
    };
  }

  @override
  String toString() => 'AvatarModel(id: $id, emoji: $emoji, name: $name)';
}
