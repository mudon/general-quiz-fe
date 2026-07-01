class Badge {
  final int id;
  final String slug;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? color;
  final bool earned;
  final String? earnedAt;

  Badge({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.iconUrl,
    this.color,
    this.earned = false,
    this.earnedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      iconUrl: json['iconUrl'],
      color: json['color'],
      earned: json['earned'] ?? false,
      earnedAt: json['earnedAt']?.toString(),
    );
  }
}
