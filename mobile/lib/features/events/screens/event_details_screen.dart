import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radii.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/event_controller.dart';
import '../models/event.dart';
import '../models/event_status.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    required this.controller,
    required this.eventId,
    super.key,
  });

  final EventController controller;
  final int eventId;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      widget.controller.selectEvent(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventDetails)),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return LoadingView(message: l10n.loading);
          }

          final error = widget.controller.error;

          if (error != null || widget.controller.selectedEvent == null) {
            if (error != null) {
              return ErrorView(
                message: localizedAppErrorMessage(l10n, error),
                retryLabel: l10n.retry,
                onRetry: error.retryable
                    ? () => widget.controller.selectEvent(widget.eventId)
                    : null,
              );
            }

            return ErrorView(
              message: l10n.eventNotFound,
              retryLabel: l10n.retry,
              onRetry: () => widget.controller.selectEvent(widget.eventId),
            );
          }

          return _EventDetailsContent(
            event: widget.controller.selectedEvent!,
            controller: widget.controller,
          );
        },
      ),
    );
  }
}

class _EventDetailsContent extends StatelessWidget {
  const _EventDetailsContent({required this.event, required this.controller});

  final Event event;
  final EventController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () => controller.selectEvent(event.id),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.extraLarge,
        ),
        children: [
          _EventHero(event: event),
          const SizedBox(height: AppSpacing.large),
          _EventInformationCard(event: event),
          const SizedBox(height: AppSpacing.medium),
          _EventMetadataCard(event: event, l10n: l10n),
        ],
      ),
    );
  }
}

class _EventHero extends StatelessWidget {
  const _EventHero({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.large),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateBadge(event.eventDate),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                _StatusBadge(
                  status: event.status,
                  label: _statusLabel(l10n, event.status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return l10n.upcoming;
      case EventStatus.running:
        return l10n.running;
      case EventStatus.completed:
        return l10n.completed;
    }
  }
}

class _EventInformationCard extends StatelessWidget {
  const _EventInformationCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _DetailsCard(
      title: l10n.eventInformation,
      icon: Icons.event_note_outlined,
      children: [
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: l10n.eventDate,
          value: event.eventDate,
        ),
        _DetailRow(
          icon: Icons.location_on_outlined,
          label: l10n.venue,
          value: event.venue,
        ),
        _DetailRow(
          icon: Icons.people_outline_rounded,
          label: l10n.guests,
          value: '${event.guestCount}',
        ),
      ],
    );
  }
}

class _EventMetadataCard extends StatelessWidget {
  const _EventMetadataCard({required this.event, required this.l10n});

  final Event event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      title: l10n.eventRecord,
      icon: Icons.info_outline_rounded,
      children: [
        _DetailRow(
          icon: Icons.tag_outlined,
          label: l10n.eventId,
          value: '${event.id}',
        ),
        _DetailRow(
          icon: Icons.schedule_outlined,
          label: l10n.createdAt,
          value: _formatDateTime(event.createdAt),
        ),
        _DetailRow(
          icon: Icons.update_outlined,
          label: l10n.updatedAt,
          value: _formatDateTime(event.updatedAt),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';

    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    return '$date $time';
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.mutedText),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        child: Text(
          date,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: AppColors.secondary,
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
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            _weekday(parsed.weekday),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
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
    const values = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return values[weekday - 1];
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final EventStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      EventStatus.upcoming => AppColors.secondary,
      EventStatus.running => Colors.blue.shade700,
      EventStatus.completed => Colors.green.shade700,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
