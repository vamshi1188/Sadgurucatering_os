import 'package:flutter/material.dart';

import 'package:sadguru_catering/core/design/app_colors.dart';
import 'package:sadguru_catering/core/design/app_radii.dart';
import 'package:sadguru_catering/core/design/app_spacing.dart';
import 'package:sadguru_catering/features/dashboard/models/dashboard_summary.dart';

class DashboardFinancialSummary extends StatelessWidget {
  const DashboardFinancialSummary({
    required this.summary,
    required this.incomeLabel,
    required this.expensesLabel,
    required this.profitLabel,
    super.key,
  });

  final DashboardSummary summary;
  final String incomeLabel;
  final String expensesLabel;
  final String profitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Metric(
              label: incomeLabel,
              value: summary.totalIncome,
              icon: Icons.arrow_downward_rounded,
              color: Colors.green.shade700,
            ),
          ),
          _Divider(),
          Expanded(
            child: _Metric(
              label: expensesLabel,
              value: summary.totalExpenses,
              icon: Icons.arrow_upward_rounded,
              color: AppColors.primary,
            ),
          ),
          _Divider(),
          Expanded(
            child: _Metric(
              label: profitLabel,
              value: summary.profit,
              icon: Icons.trending_up_rounded,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            '₹ $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 76,
      color: AppColors.border,
    );
  }
}
