class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? avatarType;
  final String? avatarValue;
  final String? selectedBadgeSlug;
  final bool emailVerified;
  final String createdAt;
  final List<Map<String, dynamic>> badges;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.avatarType,
    this.avatarValue,
    this.selectedBadgeSlug,
    required this.emailVerified,
    required this.createdAt,
    this.badges = const [],
  });

  String get displayName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      avatarType: json['avatarType'],
      avatarValue: json['avatarValue'],
      selectedBadgeSlug: json['selectedBadgeSlug'],
      emailVerified: json['emailVerified'] ?? false,
      createdAt: json['createdAt'] ?? '',
      badges: json['badges'] != null
          ? List<Map<String, dynamic>>.from(json['badges'])
          : [],
    );
  }
}
