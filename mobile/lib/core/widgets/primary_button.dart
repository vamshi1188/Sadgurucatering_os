import 'package:flutter/material.dart';

import '../design/app_dimensions.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: AppDimensions.iconSmall,
              height: AppDimensions.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : icon == null
              ? Text(label)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: AppDimensions.iconSmall),
                    const SizedBox(width: AppSpacing.small),
                    Text(label),
                  ],
                ),
    );
  }
}