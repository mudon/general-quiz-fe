class Category {
  final String id;
  final String name;
  final String path;
  final String? icon;
  final int depth;
  final String? parentId;
  final List<Category> children;
  final int totalQuestions;
  final int answeredQuestions;
  final bool completed;

  Category({
    required this.id,
    required this.name,
    required this.path,
    this.icon,
    required this.depth,
    this.parentId,
    this.children = const [],
    this.totalQuestions = 0,
    this.answeredQuestions = 0,
    this.completed = false,
  });

  Category copyWith({
    int? totalQuestions,
    int? answeredQuestions,
    bool? completed,
  }) {
    return Category(
      id: id,
      name: name,
      path: path,
      icon: icon,
      depth: depth,
      parentId: parentId,
      children: children,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      completed: completed ?? this.completed,
    );
  }

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
              .toList() ?? [],
    );
  }
}
