import 'package:chatbot/component/app_theme.dart';
import 'package:flutter/material.dart';

class AppLoadingButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppLoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.loadingLabel = 'Memproses...',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return ElevatedButton(
      onPressed: effectiveOnPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppThemePalette.primary,
        foregroundColor: AppThemePalette.onPrimary(AppThemePalette.primary),
        disabledBackgroundColor: AppThemePalette.primary.withValues(
          alpha: 0.68,
        ),
        disabledForegroundColor: AppThemePalette.onPrimary(
          AppThemePalette.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: isLoading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppThemePalette.onPrimary(AppThemePalette.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(loadingLabel),
                ],
              )
            : Row(
                key: const ValueKey('idle'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
