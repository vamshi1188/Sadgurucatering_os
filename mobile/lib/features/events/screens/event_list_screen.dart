import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/event_controller.dart';
import '../models/event.dart';
import '../widgets/event_list.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({required this.controller, this.onEventTap, super.key});

  final EventController controller;
  final ValueChanged<Event>? onEventTap;

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading && widget.controller.events.isEmpty) {
          return LoadingView(message: l10n.loading);
        }

        final error = widget.controller.error;

        if (error != null && widget.controller.events.isEmpty) {
          return ErrorView(
            message: localizedAppErrorMessage(l10n, error),
            retryLabel: l10n.retry,
            onRetry: error.retryable ? widget.controller.retry : null,
          );
        }

        if (widget.controller.events.isEmpty) {
          return RefreshIndicator(
            onRefresh: widget.controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: AppSpacing.extraLarge,
                bottom: 110,
              ),
              children: [EmptyView(message: l10n.noEvents)],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: widget.controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.medium,
              AppSpacing.medium,
              110,
            ),
            children: [
              _EventsIntro(
                title: l10n.eventsList,
                count: widget.controller.events.length,
              ),
              const SizedBox(height: AppSpacing.large),
              EventList(
                events: widget.controller.events,
                onEventTap: (event) {
                  widget.onEventTap?.call(event);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EventsIntro extends StatelessWidget {
  const _EventsIntro({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
