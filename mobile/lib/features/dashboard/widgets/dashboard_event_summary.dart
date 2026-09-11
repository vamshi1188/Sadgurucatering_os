import 'package:flutter/material.dart';

import 'package:sadguru_catering/core/design/app_spacing.dart';
import 'package:sadguru_catering/features/dashboard/models/dashboard_event.dart';

class DashboardEventSummary extends StatelessWidget {
  const DashboardEventSummary({
    required this.event,
    required this.guestsLabel,
    required this.venueLabel,
    required this.statusLabel,
    required this.incomeLabel,
    required this.expensesLabel,
    required this.profitLabel,
    super.key,
  });

  final DashboardEvent event;
  final String guestsLabel;
  final String venueLabel;
  final String statusLabel;
  final String incomeLabel;
  final String expensesLabel;
  final String profitLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.small),
            Text(event.eventDate),
            const SizedBox(height: AppSpacing.small),
            Text('$venueLabel: ${event.venue}'),
            const SizedBox(height: AppSpacing.small),
            Text('$guestsLabel: ${event.guestCount}'),
            const SizedBox(height: AppSpacing.small),
            Text('$statusLabel: ${event.status}'),
            const SizedBox(height: AppSpacing.small),
            Text('$incomeLabel: ${event.totalIncome}'),
            Text('$expensesLabel: ${event.totalExpenses}'),
            Text('$profitLabel: ${event.profit}'),
          ],
        ),
      ),
    );
  }
}
