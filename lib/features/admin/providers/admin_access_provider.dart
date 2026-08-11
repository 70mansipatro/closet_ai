import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_state.dart';
import '../../auth/domain/admin_access.dart';

final currentUserRoleProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return roleOf(auth.user);
});

final isAdminProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  return hasAdminAccess(auth.user);
});

final isSuperAdminProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  return isSuperAdmin(auth.user);
});

final currentUserPermissionsProvider = Provider<List<String>>((ref) {
  final auth = ref.watch(authControllerProvider);
  return permissionsOf(auth.user);
});
