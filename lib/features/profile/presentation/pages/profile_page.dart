import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:closet_ai/core/layout/app_layout.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/admin/providers/admin_access_provider.dart';
import 'package:closet_ai/features/auth/application/auth_state.dart';
import 'package:closet_ai/features/subscription/providers/subscription_providers.dart';
import 'package:closet_ai/features/wardrobe/application/wardrobe_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isUpdatingPhoto = false;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    context.go('/welcome');
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ref.read(imagePickerProvider);
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      setState(() => _isUpdatingPhoto = true);
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ref
            .read(authControllerProvider.notifier)
            .uploadProfilePhoto(imageBytes: bytes);
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .uploadProfilePhoto(imageFile: File(picked.path));
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isUpdatingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    try {
      setState(() => _isUpdatingPhoto = true);
      await ref.read(authControllerProvider.notifier).removeProfilePhoto();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isUpdatingPhoto = false);
    }
  }

  void _showPhotoOptions(bool hasPhoto) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  String? _firstNonEmpty(Map<String, dynamic> user, String key) {
    final value = user[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _formatGender(String? gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return 'Not set';
    }
  }

  String _formatStyle(String? style) {
    if (style == null || style.trim().isEmpty) return 'Not set';
    final normalized = style.replaceAll('-', ' ');
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: authState.isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('We couldn\'t load your profile.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).initialize(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomPadding(context)),
              children: [
                _ProfileHeader(
                  user: user,
                  isUpdatingPhoto: _isUpdatingPhoto,
                  onTapAvatar: () => _showPhotoOptions(
                    _firstNonEmpty(user, 'profileImage') != null,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Name',
                        value: _firstNonEmpty(user, 'name') ?? 'Not set',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Email',
                        value: _firstNonEmpty(user, 'email') ?? 'Not set',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Phone',
                        value: _firstNonEmpty(user, 'phone') ?? 'Not set',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Gender',
                        value: _formatGender(user['gender'] as String?),
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Height',
                        value: (user['height'] is num && (user['height'] as num) > 0)
                            ? '${user['height']} cm'
                            : 'Not set',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Weight',
                        value: (user['weight'] is num && (user['weight'] as num) > 0)
                            ? '${user['weight']} kg'
                            : 'Not set',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Preferred style',
                        value: _formatStyle(user['preferredStyle'] as String?),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/profile/edit'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/forgot-password'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: const Text('Subscription'),
                    subtitle: subscriptionAsync.when(
                      data: (subscription) => Text(
                        subscription.status == 'active'
                            ? 'Premium Active'
                            : 'Free Plan',
                      ),
                      loading: () => const Text('Loading...'),
                      error: (error, stack) => const Text('Unavailable'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/subscription'),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('Admin Panel'),
                      subtitle: const Text('Manage users, plans, and analytics'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/admin/dashboard'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/notifications'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.alarm_outlined),
                        title: const Text('Reminders'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/reminders'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: const Text('Smart Reminders'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/smart-reminders'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.tune),
                        title: const Text('Notification Settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/notifications/settings'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Sign out',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    onTap: () => _signOut(context, ref),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile header: avatar (real photo when uploaded, default icon otherwise)
/// sitting inside a soft brand-gradient ring, plus the user's real name/email.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isUpdatingPhoto,
    required this.onTapAvatar,
  });

  final Map<String, dynamic> user;
  final bool isUpdatingPhoto;
  final VoidCallback onTapAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (user['name'] as String?)?.trim();
    final email = (user['email'] as String?)?.trim();
    final photoUrl = (user['profileImage'] as String?)?.trim();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppGradients.primary.colors.first.withValues(alpha: 0.12),
            AppGradients.primary.colors.last.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: isUpdatingPhoto ? null : onTapAvatar,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                  ),
                  child: ClipOval(
                    child: Container(
                      color: theme.scaffoldBackgroundColor,
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 44,
                                color: theme.colorScheme.onSurface,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 44,
                              color: theme.colorScheme.onSurface,
                            ),
                    ),
                  ),
                ),
                if (isUpdatingPhoto)
                  const CircularProgressIndicator(),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            (name != null && name.isNotEmpty) ? name : 'My Profile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
