import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_dimensions.dart';
import '../../../core/design/app_radii.dart';
import '../../../core/design/app_spacing.dart';

class ProfitabilityMetricCard extends StatelessWidget {
  const ProfitabilityMetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    this.valueColor,
    super.key,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.small),
              decoration: BoxDecoration(
                color: (valueColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
              child: Icon(
                icon,
                color: valueColor ?? AppColors.primary,
                size: AppDimensions.iconMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ $amount',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color:
                          valueColor ??
                          Theme.of(context).textTheme.titleLarge?.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
