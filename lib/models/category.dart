class Category {
  final String id;
  final String name;
  final String path;
  final String? icon;
  final int depth;
  final String? parentId;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    required this.path,
    this.icon,
    required this.depth,
    this.parentId,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      icon: json['icon'],
      depth: json['depth'] ?? 0,
      parentId: json['parentId']?.toString(),
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => Category.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
