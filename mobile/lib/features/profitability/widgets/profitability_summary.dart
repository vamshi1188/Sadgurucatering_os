import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../localization/app_localizations.dart';
import '../models/profitability.dart';
import 'profitability_metric_card.dart';

class ProfitabilitySummary extends StatelessWidget {
  const ProfitabilitySummary({
    required this.profitability,
    super.key,
  });

  final Profitability profitability;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isProfitNegative = profitability.netProfit.startsWith('-');

    return Column(
      children: [
        ProfitabilityMetricCard(
          label: l10n.totalIncome,
          amount: profitability.totalIncome,
          icon: Icons.arrow_downward_rounded,
          valueColor: Colors.green.shade700,
        ),
        const SizedBox(height: AppSpacing.medium),
        ProfitabilityMetricCard(
          label: l10n.totalExpenses,
          amount: profitability.totalExpenses,
          icon: Icons.arrow_upward_rounded,
          valueColor: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.medium),
        ProfitabilityMetricCard(
          label: l10n.netProfit,
          amount: profitability.netProfit,
          icon: Icons.insights_rounded,
          valueColor: isProfitNegative
              ? Theme.of(context).colorScheme.error
              : AppColors.secondary,
        ),
      ],
    );
  }
}
