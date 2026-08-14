import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../auth/application/auth_state.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late String _gender;
  late String _style;
  String _email = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user ?? const {};

    _nameController = TextEditingController(text: (user['name'] ?? '').toString());
    _phoneController = TextEditingController(text: (user['phone'] ?? '').toString());
    final height = user['height'];
    _heightController = TextEditingController(
      text: (height is num && height > 0) ? height.toString() : '',
    );
    final weight = user['weight'];
    _weightController = TextEditingController(
      text: (weight is num && weight > 0) ? weight.toString() : '',
    );
    _gender = (user['gender'] as String?) ?? 'prefer-not-to-say';
    _style = (user['preferredStyle'] as String?) ?? 'casual';
    _email = (user['email'] ?? '').toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _gender,
        'preferredStyle': _style,
      };
      final height = double.tryParse(_heightController.text.trim());
      if (height != null) payload['height'] = height;
      final weight = double.tryParse(_weightController.text.trim());
      if (weight != null) payload['weight'] = weight;

      await ref.read(authControllerProvider.notifier).updateProfile(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update profile: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.navyBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              AppLayout.scrollBottomPadding(context, buffer: 32),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: _email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      helperText: 'Email cannot be changed',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value == null || value.trim().length < 2
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(
                        value: 'prefer-not-to-say',
                        child: Text('Prefer not to say'),
                      ),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) =>
                        setState(() => _gender = value ?? 'prefer-not-to-say'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) return 'Enter a valid height';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) return 'Enter a valid weight';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _style,
                    decoration: const InputDecoration(labelText: 'Preferred style'),
                    items: const [
                      DropdownMenuItem(value: 'casual', child: Text('Casual')),
                      DropdownMenuItem(
                        value: 'smart-casual',
                        child: Text('Smart casual'),
                      ),
                      DropdownMenuItem(value: 'minimal', child: Text('Minimal')),
                      DropdownMenuItem(
                        value: 'streetwear',
                        child: Text('Streetwear'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _style = value ?? 'casual'),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: _isSaving ? 'Saving...' : 'Save changes',
                    icon: Icons.check_circle_outline,
                    loading: _isSaving,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
