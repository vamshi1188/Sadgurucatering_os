import 'package:flutter/material.dart';

import 'package:sadguru_catering/core/design/app_colors.dart';
import 'package:sadguru_catering/core/design/app_radii.dart';
import 'package:sadguru_catering/core/design/app_spacing.dart';
import 'package:sadguru_catering/features/dashboard/models/dashboard_event.dart';

class DashboardEventCard extends StatelessWidget {
  const DashboardEventCard({
    required this.event,
    required this.venueLabel,
    required this.guestsLabel,
    required this.incomeLabel,
    required this.expensesLabel,
    required this.profitLabel,
    required this.statusLabel,
    super.key,
  });

  final DashboardEvent event;
  final String venueLabel;
  final String guestsLabel;
  final String incomeLabel;
  final String expensesLabel;
  final String profitLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(event.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(event.eventDate),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: event.status,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: venueLabel,
                      value: event.venue,
                    ),
                    const SizedBox(height: 7),
                    _InfoRow(
                      icon: Icons.people_outline_rounded,
                      label: guestsLabel,
                      value: '${event.guestCount}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Divider(
            height: 1,
            color: AppColors.border,
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: _Money(
                  label: incomeLabel,
                  value: event.totalIncome,
                  color: Colors.green.shade700,
                ),
              ),
              _MoneyDivider(),
              Expanded(
                child: _Money(
                  label: expensesLabel,
                  value: event.totalExpenses,
                  color: AppColors.primary,
                ),
              ),
              _MoneyDivider(),
              Expanded(
                child: _Money(
                  label: profitLabel,
                  value: event.profit,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'upcoming':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge(this.date);

  final String date;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(date);

    if (parsed == null) {
      return Container(
        width: 64,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        child: Text(
          date,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: AppColors.primary,
            child: Text(
              _month(parsed.month),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${parsed.day}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            _weekday(parsed.weekday),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 7),
        ],
      ),
    );
  }

  String _month(int month) {
    const values = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return values[month - 1];
  }

  String _weekday(int weekday) {
    const values = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    return values[weekday - 1];
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.mutedText,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            '$label: $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _Money extends StatelessWidget {
  const _Money({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹ $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _MoneyDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }
}
