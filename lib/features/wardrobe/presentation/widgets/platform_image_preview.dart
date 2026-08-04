import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformImagePreview extends StatelessWidget {
  const PlatformImagePreview({
    super.key,
    this.file,
    this.bytes,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final File? file;
  final Uint8List? bytes;
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final displayFit = fit == BoxFit.cover ? BoxFit.contain : fit;
    if (kIsWeb) {
      if (bytes != null) {
        return Image.memory(
          bytes!,
          width: width,
          height: height,
          fit: displayFit,
          errorBuilder: _buildError,
        );
      }
    } else if (file != null) {
      return Image.file(
        file!,
        width: width,
        height: height,
        fit: displayFit,
        errorBuilder: _buildError,
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: _buildError,
      );
    }

    if (assetPath != null && assetPath!.isNotEmpty) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: _buildError,
      );
    }

    return placeholder ?? _defaultPlaceholder(context);
  }

  Widget _buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return placeholder ?? _defaultPlaceholder(context);
  }

  Widget _defaultPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_not_supported_outlined)),
    );
  }
}
