import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radii.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_period.dart';
import '../widgets/dashboard_event_list.dart';
import '../widgets/dashboard_financial_summary.dart';
import '../widgets/dashboard_stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.controller,
    super.key,
  });

  final DashboardController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _financialPeriodLabel(
    AppLocalizations l10n,
    FinancialPeriod period,
  ) {
    switch (period) {
      case FinancialPeriod.today:
        return l10n.today;
      case FinancialPeriod.thisMonth:
        return l10n.thisMonth;
      case FinancialPeriod.thisYear:
        return l10n.thisYear;
    }
  }

  String _eventPeriodLabel(
    AppLocalizations l10n,
    EventPeriod period,
  ) {
    switch (period) {
      case EventPeriod.today:
        return l10n.today;
      case EventPeriod.tomorrow:
        return l10n.tomorrow;
      case EventPeriod.thisWeek:
        return l10n.thisWeek;
      case EventPeriod.thisMonth:
        return l10n.thisMonth;
      case EventPeriod.thisYear:
        return l10n.thisYear;
    }
  }

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
        if (widget.controller.isLoading &&
            widget.controller.todaySummary == null) {
          return LoadingView(message: l10n.loading);
        }

        final error = widget.controller.error;

        if (error != null && widget.controller.todaySummary == null) {
          return ErrorView(
            message: localizedAppErrorMessage(l10n, error),
            retryLabel: l10n.retry,
            onRetry: error.retryable ? widget.controller.retry : null,
          );
        }

        final today = widget.controller.todaySummary;
        final financial = widget.controller.financialSummary;
        final events = widget.controller.eventsSummary;

        if (today == null || financial == null || events == null) {
          return EmptyView(message: l10n.noData);
        }

        return RefreshIndicator(
          onRefresh: widget.controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.medium,
              AppSpacing.medium,
              110,
            ),
            children: [
              _DashboardIntro(l10n: l10n),
              const SizedBox(height: AppSpacing.large),
              _SectionHeader(
                title: l10n.todaysOverview,
                trailing: _DateLabel(),
              ),
              const SizedBox(height: AppSpacing.medium),
              _OverviewGrid(
                totalEvents: today.eventCount,
                upcoming: today.upcomingCount,
                running: today.runningCount,
                completed: today.completedCount,
                totalEventsLabel: l10n.totalEvents,
                upcomingLabel: l10n.upcoming,
                runningLabel: l10n.running,
                completedLabel: l10n.completed,
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              _SectionHeader(
                title: l10n.financialPerformance,
                trailing: _FilterPill(
                  label: _financialPeriodLabel(
                    l10n,
                    widget.controller.financialPeriod,
                  ),
                  items: [
                    PopupMenuItem(
                      value: FinancialPeriod.today,
                      child: Text(l10n.today),
                    ),
                    PopupMenuItem(
                      value: FinancialPeriod.thisMonth,
                      child: Text(l10n.thisMonth),
                    ),
                    PopupMenuItem(
                      value: FinancialPeriod.thisYear,
                      child: Text(l10n.thisYear),
                    ),
                  ],
                  onSelected: widget.controller.selectFinancialPeriod,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              DashboardFinancialSummary(
                summary: financial,
                incomeLabel: l10n.totalIncome,
                expensesLabel: l10n.totalExpenses,
                profitLabel: l10n.profit,
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              _SectionHeader(
                title: l10n.upcomingEvents,
                trailing: _FilterPill(
                  label: _eventPeriodLabel(
                    l10n,
                    widget.controller.eventPeriod,
                  ),
                  items: [
                    PopupMenuItem(
                      value: EventPeriod.today,
                      child: Text(l10n.today),
                    ),
                    PopupMenuItem(
                      value: EventPeriod.tomorrow,
                      child: Text(l10n.tomorrow),
                    ),
                    PopupMenuItem(
                      value: EventPeriod.thisWeek,
                      child: Text(l10n.thisWeek),
                    ),
                    PopupMenuItem(
                      value: EventPeriod.thisMonth,
                      child: Text(l10n.thisMonth),
                    ),
                    PopupMenuItem(
                      value: EventPeriod.thisYear,
                      child: Text(l10n.thisYear),
                    ),
                  ],
                  onSelected: widget.controller.selectEventPeriod,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              if (events.events.isEmpty)
                EmptyView(message: l10n.noEvents)
              else
                DashboardEventList(
                  events: events.events,
                  guestsLabel: l10n.guests,
                  venueLabel: l10n.venue,
                  statusLabel: l10n.status,
                  incomeLabel: l10n.income,
                  expensesLabel: l10n.expenses,
                  profitLabel: l10n.profit,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardIntro extends StatelessWidget {
  const _DashboardIntro({
    required this.l10n,
  });

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.large),
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.82),
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
                  l10n.todaysOverview,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                l10n.dashboard,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({
    required this.totalEvents,
    required this.upcoming,
    required this.running,
    required this.completed,
    required this.totalEventsLabel,
    required this.upcomingLabel,
    required this.runningLabel,
    required this.completedLabel,
  });

  final int totalEvents;
  final int upcoming;
  final int running;
  final int completed;

  final String totalEventsLabel;
  final String upcomingLabel;
  final String runningLabel;
  final String completedLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppSpacing.small;
        final width = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: DashboardStatCard(
                label: totalEventsLabel,
                value: '$totalEvents',
                icon: Icons.event_rounded,
                accentColor: AppColors.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardStatCard(
                label: upcomingLabel,
                value: '$upcoming',
                icon: Icons.event_available_rounded,
                accentColor: AppColors.secondary,
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardStatCard(
                label: runningLabel,
                value: '$running',
                icon: Icons.play_circle_outline_rounded,
                accentColor: Colors.blue.shade700,
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardStatCard(
                label: completedLabel,
                value: '$completed',
                icon: Icons.check_circle_outline_rounded,
                accentColor: Colors.green.shade700,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
  });

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        trailing,
      ],
    );
  }
}

class _DateLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Text(
      '${now.day}/${now.month}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.mutedText,
          ),
    );
  }
}

class _FilterPill<T> extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<T>(
        onSelected: onSelected,
        itemBuilder: (_) => items,
        offset: const Offset(0, 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 44,
            maxWidth: 145,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}