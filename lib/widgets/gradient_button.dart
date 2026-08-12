import 'package:flutter/material.dart';
import '../core/theme/app_gradients.dart';

enum GradientButtonVariant { primary, premium, success }

/// A pill/rounded button filled with a brand gradient. Use for hero CTAs
/// (auth submit, AI generate, premium purchase) where a flat themed button
/// isn't distinctive enough. For everyday buttons, prefer the themed
/// [ElevatedButton]/[FilledButton]/[OutlinedButton] from [AppTheme].
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GradientButtonVariant.primary,
    this.gradient,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GradientButtonVariant variant;
  final Gradient? gradient;
  final bool loading;
  final bool expand;

  Gradient get _gradient {
    if (gradient != null) return gradient!;
    switch (variant) {
      case GradientButtonVariant.primary:
        return AppGradients.primary;
      case GradientButtonVariant.premium:
        return AppGradients.premium;
      case GradientButtonVariant.success:
        return AppGradients.cyanGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final gradient = _gradient;
    final glowColor = gradient is LinearGradient ? gradient.colors.last : Colors.purple;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Container(
        width: expand ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: disabled ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (loading) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                  ] else if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
