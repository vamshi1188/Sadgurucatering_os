import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/finance_controller.dart';
import '../models/finance_period.dart';
import '../models/finance_report.dart';
import '../widgets/finance_summary_cards.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({required this.controller, super.key});

  final FinanceController controller;

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _selectPeriod(FinancePeriod period) async {
    if (period != FinancePeriod.custom) {
      await widget.controller.selectPeriod(period);
      return;
    }

    final now = DateTime.now();
    final initialStart = widget.controller.from == null
        ? DateTime(now.year, now.month, 1)
        : DateTime.parse(widget.controller.from!);
    final initialEnd = widget.controller.to == null
        ? now
        : DateTime.parse(widget.controller.to!);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd.isBefore(initialStart) ? initialStart : initialEnd,
      ),
    );
    if (range == null || !mounted) {
      return;
    }
    await widget.controller.selectPeriod(
      FinancePeriod.custom,
      from: _dateString(range.start),
      to: _dateString(range.end),
    );
  }

  String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _periodLabel(AppLocalizations l10n, FinancePeriod period) =>
      switch (period) {
        FinancePeriod.today => l10n.today,
        FinancePeriod.thisMonth => l10n.thisMonth,
        FinancePeriod.last30Days => l10n.last30Days,
        FinancePeriod.custom => l10n.customRange,
        FinancePeriod.allTime => l10n.allTime,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final report = widget.controller.report;
        final error = widget.controller.error;

        if (widget.controller.isLoading && report == null) {
          return LoadingView(message: l10n.loading);
        }
        if (error != null && report == null) {
          return ErrorView(
            message: localizedAppErrorMessage(l10n, error),
            retryLabel: l10n.retry,
            onRetry: error.retryable ? widget.controller.retry : null,
          );
        }
        if (report == null) {
          return EmptyView(message: l10n.noData);
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.finance,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  PopupMenuButton<FinancePeriod>(
                    tooltip: l10n.financePeriod,
                    initialValue: widget.controller.period,
                    onSelected: _selectPeriod,
                    itemBuilder: (context) => [
                      for (final period in FinancePeriod.values)
                        PopupMenuItem(
                          value: period,
                          child: Text(_periodLabel(l10n, period)),
                        ),
                    ],
                    child: Chip(
                      label: Text(_periodLabel(l10n, widget.controller.period)),
                      avatar: const Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                ],
              ),
              if (widget.controller.period == FinancePeriod.custom &&
                  report.from != null &&
                  report.to != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: Text(
                    '${report.from} – ${report.to}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                ),
              if (error != null) ...[
                _InlineError(
                  message: localizedAppErrorMessage(l10n, error),
                  retryLabel: l10n.retry,
                  onRetry: error.retryable ? widget.controller.retry : null,
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              FinanceSummaryCards(
                report: report,
                incomeLabel: l10n.totalIncome,
                expensesLabel: l10n.totalExpenses,
                profitLabel: l10n.netProfit,
              ),
              const SizedBox(height: AppSpacing.large),
              _SectionTitle(title: l10n.eventFinancialBreakdown),
              const SizedBox(height: AppSpacing.small),
              if (report.events.isEmpty)
                EmptyView(message: l10n.noFinanceEvents)
              else
                for (final event in report.events)
                  _EventCard(event: event, l10n: l10n),
              const SizedBox(height: AppSpacing.large),
              _SectionTitle(title: l10n.recentTransactions),
              const SizedBox(height: AppSpacing.small),
              if (report.transactions.isEmpty)
                EmptyView(message: l10n.noFinanceTransactions)
              else
                for (final transaction in report.transactions)
                  _TransactionCard(transaction: transaction, l10n: l10n),
              if (widget.controller.hasMore)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: OutlinedButton(
                      onPressed: widget.controller.isLoadingMore
                          ? null
                          : widget.controller.loadMore,
                      child: widget.controller.isLoadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.loadMore),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.l10n});

  final FinanceEvent event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.small),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '${event.eventDate} · ${_localizedStatus(l10n, event.status)}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: AppSpacing.small),
          _MoneyLine(label: l10n.totalIncome, value: event.totalIncome),
          _MoneyLine(label: l10n.totalExpenses, value: event.totalExpenses),
          _MoneyLine(
            label: l10n.netProfit,
            value: event.profit,
            emphasized: true,
          ),
        ],
      ),
    ),
  );

  String _localizedStatus(AppLocalizations l10n, String status) =>
      switch (status) {
        'upcoming' => l10n.upcoming,
        'running' => l10n.running,
        'completed' => l10n.completed,
        _ => status,
      };
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.l10n});

  final FinanceTransaction transaction;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green.shade700 : AppColors.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      child: ListTile(
        leading: Icon(
          isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: color,
        ),
        title: Text(transaction.description),
        subtitle: Text(
          '${isIncome ? l10n.income : l10n.expenses} · '
          '${transaction.eventTitle} · ${transaction.createdAt}',
        ),
        trailing: Text(
          '₹ ${formatRupees(transaction.amount)}',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          '₹ ${formatRupees(value)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            color: value.startsWith('-')
                ? AppColors.error
                : emphasized
                ? value == '0.00'
                      ? AppColors.mutedText
                      : Colors.green.shade700
                : null,
          ),
        ),
      ],
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.medium),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(child: Text(message)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    ),
  );
}
