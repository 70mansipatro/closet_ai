export const PERMISSIONS = [
  'dashboard.view',
  'users.view',
  'users.manage',
  'users.suspend',
  'users.delete',
  'subscriptions.view',
  'subscriptions.manage',
  'plans.view',
  'plans.manage',
  'payments.view',
  'analytics.view',
  'reports.view',
  'settings.view',
  'settings.manage',
  'audit.view',
  'notifications.view',
  'notifications.manage',
  'notifications.send',
];

const ADMIN_PERMISSIONS = PERMISSIONS.filter(
  (permission) => !['users.delete', 'settings.manage'].includes(permission)
);

export const ROLE_PERMISSIONS = {
  admin: ADMIN_PERMISSIONS,
  super_admin: PERMISSIONS,
};

export const getPermissionsForRole = (role) => ROLE_PERMISSIONS[role] || [];

export const roleHasPermission = (role, permission) => getPermissionsForRole(role).includes(permission);
