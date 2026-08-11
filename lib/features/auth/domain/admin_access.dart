String? roleOf(Map<String, dynamic>? user) => user?['role']?.toString();

bool hasAdminAccess(Map<String, dynamic>? user) {
  final role = roleOf(user);
  return role == 'admin' || role == 'super_admin';
}

bool isSuperAdmin(Map<String, dynamic>? user) => roleOf(user) == 'super_admin';

List<String> permissionsOf(Map<String, dynamic>? user) {
  final raw = user?['permissions'];
  if (raw is List) return raw.map((e) => e.toString()).toList();
  return const [];
}
