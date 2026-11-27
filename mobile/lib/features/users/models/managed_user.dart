class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
    required this.createdAt,
  });

  final int id;
  final String username;
  final String role;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime createdAt;

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final username = json['username'];
    final role = json['role'];
    final isActive = json['is_active'];
    final mustChangePassword = json['must_change_password'];
    final createdAt = json['created_at'];
    if (id is! int ||
        username is! String ||
        role is! String ||
        isActive is! bool ||
        mustChangePassword is! bool ||
        createdAt is! String) {
      throw const FormatException('Invalid user response');
    }

    return ManagedUser(
      id: id,
      username: username,
      role: role.toLowerCase(),
      isActive: isActive,
      mustChangePassword: mustChangePassword,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
