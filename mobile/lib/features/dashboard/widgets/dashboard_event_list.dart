import 'package:flutter/material.dart';

import 'package:sadguru_catering/core/design/app_spacing.dart';
import 'package:sadguru_catering/features/dashboard/models/dashboard_event.dart';
import 'dashboard_event_card.dart';

class DashboardEventList extends StatelessWidget {
  const DashboardEventList({
    required this.events,
    required this.guestsLabel,
    required this.venueLabel,
    required this.statusLabel,
    required this.incomeLabel,
    required this.expensesLabel,
    required this.profitLabel,
    super.key,
  });

  final List<DashboardEvent> events;
  final String guestsLabel;
  final String venueLabel;
  final String statusLabel;
  final String incomeLabel;
  final String expensesLabel;
  final String profitLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < events.length; index++) ...[
          DashboardEventCard(
            event: events[index],
            guestsLabel: guestsLabel,
            venueLabel: venueLabel,
            statusLabel: statusLabel,
            incomeLabel: incomeLabel,
            expensesLabel: expensesLabel,
            profitLabel: profitLabel,
          ),
          if (index != events.length - 1)
            const SizedBox(height: AppSpacing.medium),
        ],
      ],
    );
  }
}
