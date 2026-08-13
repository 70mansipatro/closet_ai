import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/section_card.dart';
import '../../application/wardrobe_state.dart';
import '../../data/wardrobe_repository.dart';
import '../../domain/wardrobe_item.dart';
import '../widgets/platform_image_preview.dart';

// Controlled vocabularies mirroring backend/src/constants/clothingOptions.js
// so dropdown choices always map onto values the backend/AI already agree on.
class _Opt {
  const _Opt(this.value, this.label);
  final String value;
  final String label;
}

const _categoryOptions = [
  _Opt('top', 'Top'),
  _Opt('bottom', 'Bottom'),
  _Opt('dress', 'Dress'),
  _Opt('outerwear', 'Outerwear'),
  _Opt('shoes', 'Footwear'),
  _Opt('accessory', 'Accessory'),
  _Opt('activewear', 'Activewear'),
  _Opt('innerwear', 'Innerwear'),
  _Opt('other', 'Other'),
];

const _subCategorySuggestions = <String, List<String>>{
  'top': ['T-Shirt', 'Shirt', 'Blouse', 'Tank Top', 'Sweater', 'Hoodie'],
  'bottom': ['Jeans', 'Trousers', 'Shorts', 'Skirt', 'Leggings'],
  'dress': ['Casual Dress', 'Party Dress', 'Maxi Dress', 'Mini Dress', 'Midi Dress', 'Formal Dress'],
  'outerwear': ['Jacket', 'Coat', 'Blazer', 'Cardigan'],
  'shoes': ['Sneakers', 'Boots', 'Heels', 'Sandals', 'Flats'],
  'accessory': ['Bag', 'Watch', 'Belt', 'Scarf', 'Hat', 'Jewelry'],
  'activewear': ['Sports Bra', 'Track Pants', 'Gym Top', 'Joggers'],
  'innerwear': ['Bra', 'Underwear', 'Vest', 'Thermal'],
  'other': <String>[],
};

const _colorOptions = [
  _Opt('black', 'Black'),
  _Opt('white', 'White'),
  _Opt('red', 'Red'),
  _Opt('blue', 'Blue'),
  _Opt('green', 'Green'),
  _Opt('yellow', 'Yellow'),
  _Opt('pink', 'Pink'),
  _Opt('purple', 'Purple'),
  _Opt('orange', 'Orange'),
  _Opt('brown', 'Brown'),
  _Opt('grey', 'Grey'),
  _Opt('beige', 'Beige'),
  _Opt('multi-color', 'Multi-color'),
  _Opt('other', 'Other'),
];

const _patternOptions = [
  _Opt('solid', 'Solid'),
  _Opt('striped', 'Striped'),
  _Opt('checked', 'Checked'),
  _Opt('floral', 'Floral'),
  _Opt('printed', 'Printed'),
  _Opt('polka-dot', 'Polka Dot'),
  _Opt('geometric', 'Geometric'),
  _Opt('abstract', 'Abstract'),
  _Opt('embroidered', 'Embroidered'),
  _Opt('other', 'Other'),
];

const _materialOptions = [
  _Opt('cotton', 'Cotton'),
  _Opt('denim', 'Denim'),
  _Opt('linen', 'Linen'),
  _Opt('silk', 'Silk'),
  _Opt('wool', 'Wool'),
  _Opt('polyester', 'Polyester'),
  _Opt('leather', 'Leather'),
  _Opt('rayon', 'Rayon'),
  _Opt('chiffon', 'Chiffon'),
  _Opt('velvet', 'Velvet'),
  _Opt('other', 'Other'),
  _Opt('unknown', 'Unknown'),
];

const _styleOptions = [
  _Opt('casual', 'Casual'),
  _Opt('formal', 'Formal'),
  _Opt('party', 'Party'),
  _Opt('sporty', 'Sporty'),
  _Opt('streetwear', 'Streetwear'),
  _Opt('traditional', 'Traditional'),
  _Opt('business', 'Business'),
  _Opt('minimal', 'Minimal'),
  _Opt('elegant', 'Elegant'),
  _Opt('ethnic', 'Ethnic'),
];

const _seasonOptions = [
  _Opt('spring', 'Spring'),
  _Opt('summer', 'Summer'),
  _Opt('autumn', 'Autumn'),
  _Opt('winter', 'Winter'),
  _Opt('all-season', 'All Season'),
];

const _occasionOptions = [
  _Opt('casual', 'Casual'),
  _Opt('office', 'Office'),
  _Opt('party', 'Party'),
  _Opt('wedding', 'Wedding'),
  _Opt('travel', 'Travel'),
  _Opt('workout', 'Workout'),
  _Opt('date', 'Date'),
  _Opt('festival', 'Festival'),
  _Opt('formal', 'Formal'),
  _Opt('daily-wear', 'Daily Wear'),
];

const _weatherOptions = [
  _Opt('hot', 'Hot'),
  _Opt('warm', 'Warm'),
  _Opt('mild', 'Mild'),
  _Opt('cool', 'Cool'),
  _Opt('cold', 'Cold'),
  _Opt('rainy', 'Rainy'),
];

const _fitOptions = [
  _Opt('slim', 'Slim'),
  _Opt('regular', 'Regular'),
  _Opt('relaxed', 'Relaxed'),
  _Opt('oversized', 'Oversized'),
  _Opt('not-set', 'Not Set'),
];

const _sizeOptions = [
  _Opt('xs', 'XS'),
  _Opt('s', 'S'),
  _Opt('m', 'M'),
  _Opt('l', 'L'),
  _Opt('xl', 'XL'),
  _Opt('xxl', 'XXL'),
  _Opt('custom', 'Custom'),
  _Opt('not-set', 'Not Set'),
];

const _laundryOptions = [
  _Opt('clean', 'Clean'),
  _Opt('dirty', 'Dirty'),
  _Opt('washing', 'Washing'),
  _Opt('drying', 'Drying'),
  _Opt('ironing', 'Ironing'),
  _Opt('ready', 'Ready'),
  _Opt('in-use', 'In Use'),
  _Opt('repair', 'Repair'),
];

const _aiLoadingMessages = [
  'AI is identifying your clothing...',
  'Detecting category, color and style...',
  'Preparing clothing details...',
];

class WardrobeFormPage extends ConsumerStatefulWidget {
  const WardrobeFormPage({super.key, this.item, this.initialCategory});

  final WardrobeItem? item;
  final String? initialCategory;

  @override
  ConsumerState<WardrobeFormPage> createState() => _WardrobeFormPageState();
}

class _WardrobeFormPageState extends ConsumerState<WardrobeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();

  String _category = 'top';
  String _subCategory = '';
  String _color = '';
  List<String> _secondaryColors = [];
  String _pattern = '';
  String _material = '';
  String _style = '';
  String _season = 'all-season';
  List<String> _occasions = [];
  List<String> _weatherSuitability = [];
  String _fit = '';
  String _size = '';
  String _laundryStatus = 'clean';
  bool _favorite = false;
  DateTime? _purchaseDate;

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;
  bool _isAnalyzing = false;
  bool _dirty = false;

  bool _aiAnalyzed = false;
  Map<String, num?> _aiConfidence = const {};
  Timer? _loadingMessageTimer;
  int _loadingMessageIndex = 0;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final initialCategory = widget.initialCategory;

    if (item != null) {
      _nameController.text = item.name;
      _brandController.text = item.brand;
      _notesController.text = item.notes;
      _priceController.text = item.purchasePrice > 0 ? item.purchasePrice.toString() : '';
      _category = _normalizeCategory(item.category);
      _subCategory = item.subCategory;
      _color = item.color;
      _secondaryColors = [...item.secondaryColors];
      _pattern = item.pattern;
      _material = item.material;
      _style = item.style;
      _season = item.season;
      _occasions = [...item.occasions];
      _weatherSuitability = [...item.weatherSuitability];
      _fit = item.fit;
      _size = item.size;
      _laundryStatus = item.laundryStatus;
      _favorite = item.favorite;
      _purchaseDate = item.purchaseDate != null ? DateTime.tryParse(item.purchaseDate!) : null;
      _aiAnalyzed = item.aiAnalyzed;
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
      case 'dress':
      case 'dresses':
        return 'dress';
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
      case 'activewear':
        return 'activewear';
      case 'innerwear':
        return 'innerwear';
      case 'other':
        return 'other';
      default:
        return 'top';
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _loadingMessageTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ref.read(imagePickerProvider);
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return;

    _markDirty();
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

  void _removeImage() {
    _markDirty();
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  bool get _hasImage =>
      _selectedImageFile != null ||
      _selectedImageBytes != null ||
      (widget.item?.imageUrl.isNotEmpty ?? false);

  void _startLoadingMessageCycle() {
    _loadingMessageIndex = 0;
    _loadingMessageTimer?.cancel();
    _loadingMessageTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      setState(() {
        _loadingMessageIndex = (_loadingMessageIndex + 1) % _aiLoadingMessages.length;
      });
    });
  }

  Future<void> _analyzeImage() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    _startLoadingMessageCycle();

    try {
      final response = await WardrobeRepository().analyzeImage(
        imageFile: _selectedImageFile,
        imageBytes: _selectedImageBytes,
      );

      if (!mounted) return;
      setState(() {
        _applyAiResponse(response);
        _aiAnalyzed = true;
        _dirty = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ AI detected your clothing details')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAiErrorMessage(error))),
      );
    } finally {
      _loadingMessageTimer?.cancel();
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _applyAiResponse(Map<String, dynamic> response) {
    String? asString(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    List<String> asStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    final name = asString(response['name']);
    if (name != null) _nameController.text = name;

    final category = asString(response['category']);
    if (category != null) _category = _normalizeCategory(category);

    final subCategory = asString(response['subcategory'] ?? response['subCategory']);
    if (subCategory != null) _subCategory = subCategory;

    final color = asString(response['color']);
    if (color != null) _color = color.toLowerCase();

    _secondaryColors = asStringList(response['secondaryColors']);

    final pattern = asString(response['pattern']);
    if (pattern != null) _pattern = pattern;

    final material = asString(response['material']);
    if (material != null) _material = material;

    final style = asString(response['style']);
    if (style != null) _style = style;

    final season = asString(response['season']);
    if (season != null) _season = season;

    _occasions = asStringList(response['occasions']);
    _weatherSuitability = asStringList(response['weatherSuitability']);

    final fit = asString(response['fit']);
    if (fit != null) _fit = fit;

    // Brand/size are never fabricated by the AI service, but only overwrite
    // an empty field so we never clobber something the user already typed.
    final brand = asString(response['brand']);
    if (brand != null && _brandController.text.trim().isEmpty) {
      _brandController.text = brand;
    }
    final size = asString(response['size']);
    if (size != null && _size.isEmpty) _size = size.toLowerCase();

    final confidence = response['confidence'];
    if (confidence is Map) {
      _aiConfidence = confidence.map(
        (key, value) => MapEntry(key.toString(), num.tryParse(value?.toString() ?? '')),
      );
    }
  }

  String _friendlyAiErrorMessage(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return "AI analysis is taking longer than expected. Please try again.";
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return "AI service is temporarily unavailable. Please try again shortly.";
      }
      final data = error.response?.data;
      if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
    }
    return "Couldn't analyze this image. Please try again.";
  }

  Future<void> _pickPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(now.year - 15),
      lastDate: now,
    );
    if (picked != null) {
      _markDirty();
      setState(() => _purchaseDate = picked);
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'name': _nameController.text.trim(),
      'category': _category,
      'subCategory': _subCategory.trim(),
      'color': _color.trim(),
      'secondaryColors': jsonEncode(_secondaryColors),
      'pattern': _pattern.trim(),
      'material': _material.trim(),
      'style': _style.trim(),
      'season': _season,
      'occasions': jsonEncode(_occasions),
      'weatherSuitability': jsonEncode(_weatherSuitability),
      'fit': _fit.trim(),
      'brand': _brandController.text.trim(),
      'size': _size.trim(),
      'purchasePrice': _priceController.text.trim().isEmpty
          ? 0
          : double.tryParse(_priceController.text.trim()) ?? 0,
      if (_purchaseDate != null) 'purchaseDate': _purchaseDate!.toIso8601String(),
      'favorite': _favorite,
      'laundryStatus': _laundryStatus,
      'notes': _notesController.text.trim(),
      'aiAnalyzed': _aiAnalyzed,
      if (_aiAnalyzed) 'aiConfidence': jsonEncode(_aiConfidence),
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final payload = _buildPayload();

      if (!_isEditing) {
        await ref.read(wardrobeControllerProvider.notifier).createItem(
              payload,
              imageFile: _selectedImageFile,
              imageBytes: _selectedImageBytes,
            );
      } else {
        await ref.read(wardrobeControllerProvider.notifier).updateItem(
              widget.item!.id,
              payload,
              imageFile: _selectedImageFile,
              imageBytes: _selectedImageBytes,
            );
      }
      if (!mounted) return;
      _dirty = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Clothing updated successfully.' : '✨ Clothing added to your wardrobe',
          ),
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      final message = _extractErrorMessage(error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          final nestedMessage = data['data']['message'] ?? data['data']['error'];
          if (nestedMessage is String && nestedMessage.isNotEmpty) {
            return nestedMessage;
          }
        }
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'You appear to be offline. Check your connection and try again.';
      }
      if (error.response?.statusCode != null) {
        return 'Your clothing details could not be saved. Please try again.';
      }
    }
    return 'Your clothing details could not be saved. Please try again.';
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscardChanges();
        if (!context.mounted || !shouldPop) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Clothing' : 'Add Clothing'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            onChanged: _markDirty,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildImageSection(context),
                const SizedBox(height: 16),
                if (_hasImage) _buildAnalyzeSection(context),
                if (_aiAnalyzed) ...[
                  const SizedBox(height: 16),
                  _buildAiSummaryCard(context),
                ],
                const SizedBox(height: 16),
                _buildBasicInformationSection(),
                const SizedBox(height: 12),
                _buildAppearanceSection(),
                const SizedBox(height: 12),
                _buildSeasonUsageSection(),
                const SizedBox(height: 12),
                _buildProductDetailsSection(),
                const SizedBox(height: 12),
                _buildWardrobeStatusSection(),
                const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final theme = Theme.of(context);

    if (!_hasImage) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.lightSurfaceAlt,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(
          children: [
            const Text('👕', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              'Add clothing photo',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Take a photo or choose from your gallery',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildPickerButton(Icons.photo_camera_outlined, 'Camera', ImageSource.camera)),
                const SizedBox(width: 12),
                Expanded(child: _buildPickerButton(Icons.photo_library_outlined, 'Gallery', ImageSource.gallery)),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            height: 280,
            color: AppColors.lightSurfaceAlt,
            child: PlatformImagePreview(
              file: _selectedImageFile,
              bytes: _selectedImageBytes,
              imageUrl: widget.item?.imageUrl,
              height: 280,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPickerButton(Icons.sync_alt_rounded, 'Change Image', ImageSource.gallery)),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickerButton(IconData icon, String label, ImageSource source) {
    return OutlinedButton.icon(
      onPressed: () => _pickImage(source),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildAnalyzeSection(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          label: _isAnalyzing ? _aiLoadingMessages[_loadingMessageIndex] : 'Analyze with AI',
          icon: Icons.auto_awesome_outlined,
          loading: _isAnalyzing,
          variant: GradientButtonVariant.premium,
          onPressed: _isAnalyzing ? null : _analyzeImage,
        ),
        if (!_isAnalyzing) ...[
          const SizedBox(height: 6),
          Text(
            'Automatically identify clothing details from your photo',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildAiSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final badges = <String>[
      if (_subCategory.isNotEmpty) _subCategory,
      if (_color.isNotEmpty) _labelFor(_colorOptions, _color),
      if (_season.isNotEmpty) _labelFor(_seasonOptions, _season),
      if (_style.isNotEmpty) _labelFor(_styleOptions, _style),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                'AI Analysis Complete',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Review the details before saving.', style: theme.textTheme.bodySmall),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final badge in badges)
                  Chip(
                    avatar: const Text('✓'),
                    label: Text(badge),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _labelFor(List<_Opt> options, String value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  Widget _buildBasicInformationSection() {
    final subCategorySuggestions = _subCategorySuggestions[_category] ?? const [];
    return SectionCard(
      title: 'Basic Information',
      icon: Icons.checkroom_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Clothing Name',
              hintText: 'e.g. Black Party Dress',
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _OptionField(
            label: 'Category',
            options: _categoryOptions,
            value: _category,
            allowCustom: false,
            onChanged: (value) {
              _markDirty();
              setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          _OptionField(
            label: 'Subcategory',
            options: [for (final s in subCategorySuggestions) _Opt(s, s), const _Opt('Other', 'Other')],
            value: _subCategory,
            onChanged: (value) {
              _markDirty();
              setState(() => _subCategory = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return SectionCard(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OptionField(
            label: 'Color',
            options: _colorOptions,
            value: _color,
            confidence: _aiConfidence['color'],
            onChanged: (value) {
              _markDirty();
              setState(() => _color = value);
            },
          ),
          const SizedBox(height: 16),
          _MultiSelectChips(
            label: 'Secondary Colors',
            options: _colorOptions.where((o) => o.value != 'other').toList(),
            selected: _secondaryColors,
            onChanged: (value) {
              _markDirty();
              setState(() => _secondaryColors = value);
            },
          ),
          const SizedBox(height: 16),
          _OptionField(
            label: 'Pattern',
            options: _patternOptions,
            value: _pattern,
            confidence: _aiConfidence['pattern'],
            onChanged: (value) {
              _markDirty();
              setState(() => _pattern = value);
            },
          ),
          const SizedBox(height: 12),
          _OptionField(
            label: 'Material',
            options: _materialOptions,
            value: _material,
            confidence: _aiConfidence['material'],
            onChanged: (value) {
              _markDirty();
              setState(() => _material = value);
            },
          ),
          const SizedBox(height: 12),
          _OptionField(
            label: 'Style',
            options: _styleOptions,
            value: _style,
            allowCustom: false,
            confidence: _aiConfidence['style'],
            onChanged: (value) {
              _markDirty();
              setState(() => _style = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonUsageSection() {
    return SectionCard(
      title: 'Season & Usage',
      icon: Icons.wb_sunny_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OptionField(
            label: 'Season',
            options: _seasonOptions,
            value: _season,
            allowCustom: false,
            confidence: _aiConfidence['season'],
            onChanged: (value) {
              _markDirty();
              setState(() => _season = value);
            },
          ),
          const SizedBox(height: 16),
          _MultiSelectChips(
            label: 'Occasion',
            options: _occasionOptions,
            selected: _occasions,
            onChanged: (value) {
              _markDirty();
              setState(() => _occasions = value);
            },
          ),
          const SizedBox(height: 16),
          _MultiSelectChips(
            label: 'Weather Suitability',
            options: _weatherOptions,
            selected: _weatherSuitability,
            onChanged: (value) {
              _markDirty();
              setState(() => _weatherSuitability = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsSection() {
    final dateFormat = DateFormat('d MMM yyyy');
    return SectionCard(
      title: 'Product Details',
      icon: Icons.info_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _brandController,
            decoration: const InputDecoration(labelText: 'Brand'),
          ),
          const SizedBox(height: 12),
          _OptionField(
            label: 'Size',
            options: _sizeOptions,
            value: _size,
            onChanged: (value) {
              _markDirty();
              setState(() => _size = value);
            },
          ),
          const SizedBox(height: 12),
          _OptionField(
            label: 'Fit',
            options: _fitOptions,
            value: _fit,
            allowCustom: false,
            onChanged: (value) {
              _markDirty();
              setState(() => _fit = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: const InputDecoration(labelText: 'Price (optional)'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickPurchaseDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Purchase Date (optional)'),
              child: Text(
                _purchaseDate != null ? dateFormat.format(_purchaseDate!) : 'Not set',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
        ],
      ),
    );
  }

  Widget _buildWardrobeStatusSection() {
    return SectionCard(
      title: 'Wardrobe Status',
      icon: Icons.checkroom_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OptionField(
            label: 'Laundry Status',
            options: _laundryOptions,
            value: _laundryStatus,
            allowCustom: false,
            onChanged: (value) {
              _markDirty();
              setState(() => _laundryStatus = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add to Favorites'),
            secondary: Icon(_favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
            value: _favorite,
            onChanged: (value) {
              _markDirty();
              setState(() => _favorite = value);
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ReadOnlyStat(
                  label: 'Wear Count',
                  value: (widget.item?.wearCount ?? 0).toString(),
                ),
              ),
              Expanded(
                child: _ReadOnlyStat(
                  label: 'Last Worn',
                  value: widget.item?.lastWorn ?? 'Not Set',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyStat extends StatelessWidget {
  const _ReadOnlyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// A dropdown backed by a controlled vocabulary that reveals a free-text
/// field when the value doesn't match any option (or the user picks
/// "Other") — lets AI-populated values stay editable without locking the
/// user out of anything the dropdown doesn't cover.
class _OptionField extends StatefulWidget {
  const _OptionField({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.allowCustom = true,
    this.confidence,
  });

  final String label;
  final List<_Opt> options;
  final String value;
  final ValueChanged<String> onChanged;
  final bool allowCustom;
  final num? confidence;

  @override
  State<_OptionField> createState() => _OptionFieldState();
}

class _OptionFieldState extends State<_OptionField> {
  late TextEditingController _customController;
  bool _isOther = false;

  bool get _hasOtherOption => widget.options.any((o) => o.value.toLowerCase() == 'other');

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController();
    _syncFromValue();
  }

  @override
  void didUpdateWidget(covariant _OptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _syncFromValue();
    }
  }

  void _syncFromValue() {
    final matches = widget.options.any((o) => o.value == widget.value);
    _isOther = widget.allowCustom && _hasOtherOption && widget.value.isNotEmpty && !matches;
    if (_isOther) {
      _customController.text = widget.value;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.options.any((o) => o.value == widget.value);
    final dropdownValue = _isOther
        ? widget.options.firstWhere((o) => o.value.toLowerCase() == 'other').value
        : (matches ? widget.value : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixText: widget.confidence != null ? '${widget.confidence!.round()}%' : null,
          ),
          items: [
            for (final option in widget.options) DropdownMenuItem(value: option.value, child: Text(option.label)),
          ],
          onChanged: (selected) {
            if (selected == null) return;
            final selectedIsOther = selected.toLowerCase() == 'other';
            setState(() => _isOther = selectedIsOther);
            widget.onChanged(selectedIsOther ? _customController.text : selected);
          },
        ),
        if (_isOther) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customController,
            decoration: InputDecoration(labelText: 'Custom ${widget.label.toLowerCase()}'),
            onChanged: widget.onChanged,
          ),
        ],
        if (widget.confidence != null && widget.confidence! < 60) ...[
          const SizedBox(height: 4),
          Text(
            'AI is not confident about this field.',
            style: TextStyle(fontSize: 11, color: AppColors.textOnLightMuted),
          ),
        ],
      ],
    );
  }
}

class _MultiSelectChips extends StatelessWidget {
  const _MultiSelectChips({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<_Opt> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(option.label),
                selected: selected.contains(option.value),
                onSelected: (isSelected) {
                  final next = [...selected];
                  if (isSelected) {
                    next.add(option.value);
                  } else {
                    next.remove(option.value);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}
