import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../widgets/gradient_button.dart';
import '../../application/wardrobe_state.dart';
import '../../data/wardrobe_repository.dart';
import '../../domain/wardrobe_item.dart';
import '../widgets/platform_image_preview.dart';

class WardrobeFormPage extends ConsumerStatefulWidget {
  const WardrobeFormPage({super.key, this.item, this.initialCategory});

  final WardrobeItem? item;
  final String? initialCategory;

  @override
  ConsumerState<WardrobeFormPage> createState() => _WardrobeFormPageState();
}

class _WardrobeFormPageState extends ConsumerState<WardrobeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _notesController = TextEditingController();
  final _occasionController = TextEditingController();
  final _priceController = TextEditingController();
  final _colorController = TextEditingController();
  final _secondaryColorController = TextEditingController();
  final _patternController = TextEditingController();
  final _fabricController = TextEditingController();
  String _category = 'top';
  String _season = 'all-season';
  String _laundryStatus = 'clean';
  bool _favorite = false;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final initialCategory = widget.initialCategory;

    if (item != null) {
      _titleController.text = item.subCategory;
      _brandController.text = item.brand;
      _sizeController.text = item.size;
      _notesController.text = item.notes;
      _occasionController.text = item.occasion;
      _priceController.text = item.purchasePrice > 0
          ? item.purchasePrice.toString()
          : '';
      _colorController.text = item.color;
      _secondaryColorController.text = '';
      _patternController.text = '';
      _fabricController.text = '';
      _category = _normalizeCategory(item.category);
      _season = item.season;
      _laundryStatus = item.laundryStatus;
      _favorite = item.favorite;
    } else if (initialCategory != null && initialCategory.isNotEmpty) {
      _category = _normalizeCategory(initialCategory);
    }
  }

  String _normalizeCategory(String category) {
    final normalized = category.trim().toLowerCase();
    switch (normalized) {
      case 'top':
      case 'tops':
        return 'top';
      case 'bottom':
      case 'bottoms':
        return 'bottom';
      case 'shoe':
      case 'shoes':
      case 'footwear':
        return 'shoes';
      case 'outerwear':
      case 'jacket':
      case 'coat':
        return 'outerwear';
      case 'accessory':
      case 'accessories':
        return 'accessory';
      case 'other':
        return 'other';
      default:
        return 'top';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _notesController.dispose();
    _occasionController.dispose();
    _priceController.dispose();
    _colorController.dispose();
    _secondaryColorController.dispose();
    _patternController.dispose();
    _fabricController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ref.read(imagePickerProvider);
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageFile = null;
        _selectedImageBytes = bytes;
      });
    } else {
      setState(() {
        _selectedImageFile = File(picked.path);
        _selectedImageBytes = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    debugPrint('[UI] Starting AI image analysis');
    debugPrint(
      '[UI] AI analyze image selected path=${_selectedImageFile?.path} bytesLength=${_selectedImageBytes?.length}',
    );
    try {
      final response = await WardrobeRepository().analyzeImage(
        imageFile: _selectedImageFile,
        imageBytes: _selectedImageBytes,
      );
      debugPrint('[UI] AI analyze response: $response');

      if (!mounted) return;
      setState(() {
        _category = response['category']?.toString() ?? _category;
        _titleController.text =
            response['subCategory']?.toString() ?? _titleController.text;
        _colorController.text =
            response['color']?.toString() ?? _colorController.text;
        _secondaryColorController.text =
            response['secondaryColor']?.toString() ??
            _secondaryColorController.text;
        _patternController.text =
            response['pattern']?.toString() ?? _patternController.text;
        _fabricController.text =
            response['fabric']?.toString() ?? _fabricController.text;
        _brandController.text =
            response['brand']?.toString() ?? _brandController.text;
        _season = response['season']?.toString() ?? _season;
        _occasionController.text =
            response['occasion']?.toString() ?? _occasionController.text;
        final purchasePrice = response['purchasePrice'];
        if (purchasePrice != null) {
          _priceController.text = purchasePrice.toString();
        }
      });
    } catch (error) {
      if (!mounted) return;
      final message = _extractErrorMessage(error);
      debugPrint('[UI] AI analyze error: $message');
      debugPrint('[UI] AI analyze exception: $error');
      debugPrint('[UI] AI analyze stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'category': _category,
        'subCategory': _titleController.text.trim(),
        'color': _colorController.text.trim(),
        'season': _season,
        'occasion': _occasionController.text.trim(),
        'brand': _brandController.text.trim(),
        'size': _sizeController.text.trim(),
        'purchasePrice': _priceController.text.trim().isEmpty
            ? 0
            : double.tryParse(_priceController.text.trim()) ?? 0,
        'favorite': _favorite,
        'laundryStatus': _laundryStatus,
        'notes': _notesController.text.trim(),
      };

      if (widget.item == null) {
        await ref
            .read(wardrobeControllerProvider.notifier)
            .createItem(
              payload,
              imageFile: _selectedImageFile,
              imageBytes: _selectedImageBytes,
            );
      } else {
        await ref
            .read(wardrobeControllerProvider.notifier)
            .updateItem(
              widget.item!.id,
              payload,
              imageFile: _selectedImageFile,
              imageBytes: _selectedImageBytes,
            );
      }
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      final message = _extractErrorMessage(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (data['data'] is Map) {
          final nestedMessage =
              data['data']['message'] ?? data['data']['error'];
          if (nestedMessage is String && nestedMessage.isNotEmpty) {
            return nestedMessage;
          }
        }
      }
      if (error.response?.statusCode != null) {
        return 'The server returned ${error.response!.statusCode}. Please try again.';
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    if (error is Error) {
      return error.toString();
    }

    return error.toString().contains('Exception')
        ? 'We could not save that clothing item. Please try again.'
        : error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add clothing' : 'Edit clothing'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Image Preview',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PlatformImagePreview(
                  file: _selectedImageFile,
                  bytes: _selectedImageBytes,
                  imageUrl: widget.item?.imageUrl,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  placeholder: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: Text('Upload an image')),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.photo_camera_outlined),
                      onPressed: () => _pickImage(ImageSource.camera),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: () => _pickImage(ImageSource.gallery),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: _isAnalyzing ? 'Analyzing…' : 'Analyze with AI',
                icon: Icons.auto_awesome_outlined,
                loading: _isAnalyzing,
                variant: GradientButtonVariant.premium,
                onPressed: _isAnalyzing ? null : _analyzeImage,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: const [
                  DropdownMenuItem(value: 'top', child: Text('Top')),
                  DropdownMenuItem(value: 'bottom', child: Text('Bottom')),
                  DropdownMenuItem(value: 'dress', child: Text('Dress')),
                  DropdownMenuItem(
                    value: 'outerwear',
                    child: Text('Outerwear'),
                  ),
                  DropdownMenuItem(value: 'shoes', child: Text('Shoes')),
                  DropdownMenuItem(
                    value: 'accessory',
                    child: Text('Accessory'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) =>
                    setState(() => _category = value ?? 'top'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Sub Category'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _secondaryColorController,
                decoration: const InputDecoration(labelText: 'Secondary Color'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _patternController,
                decoration: const InputDecoration(labelText: 'Pattern'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fabricController,
                decoration: const InputDecoration(labelText: 'Fabric'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _season,
                items: const [
                  DropdownMenuItem(value: 'spring', child: Text('Spring')),
                  DropdownMenuItem(value: 'summer', child: Text('Summer')),
                  DropdownMenuItem(value: 'autumn', child: Text('Autumn')),
                  DropdownMenuItem(value: 'winter', child: Text('Winter')),
                  DropdownMenuItem(
                    value: 'all-season',
                    child: Text('All season'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _season = value ?? 'all-season'),
                decoration: const InputDecoration(labelText: 'Season'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _occasionController,
                decoration: const InputDecoration(labelText: 'Occasion'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 24),
              if (widget.item != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wear History',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _ReadOnlyInfoRow(
                          label: 'Last Worn',
                          value: widget.item!.lastWorn?.isNotEmpty == true
                              ? widget.item!.lastWorn!
                              : 'Not set',
                        ),
                        _ReadOnlyInfoRow(
                          label: 'Wear Count',
                          value: widget.item!.wearCount.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              GradientButton(
                label: _isSubmitting ? 'Saving…' : 'Save',
                icon: Icons.save_outlined,
                loading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  const _ReadOnlyInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
