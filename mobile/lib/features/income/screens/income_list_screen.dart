import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/income_controller.dart';
import '../models/income.dart';
import '../widgets/income_list.dart';
import '../widgets/income_summary.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({
    required this.controller,
    this.onAddIncome,
    this.canEdit = true,
    super.key,
  });

  final IncomeController controller;
  final VoidCallback? onAddIncome;
  final bool canEdit;

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _confirmDelete(Income income) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteIncome),
        content: Text(l10n.deleteIncomeConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.controller.deleteIncome(income.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading && widget.controller.incomes.isEmpty) {
          return LoadingView(message: l10n.loading);
        }

        final error = widget.controller.error;
        if (error != null && widget.controller.incomes.isEmpty) {
          return ErrorView(
            message: localizedAppErrorMessage(l10n, error),
            retryLabel: l10n.retry,
            onRetry: widget.controller.retry,
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
              AppSpacing.extraLarge,
            ),
            children: [
              IncomeSummary(
                label: l10n.totalIncome,
                amount: widget.controller.totalIncome,
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  localizedAppErrorMessage(l10n, error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              if (widget.onAddIncome != null) ...[
                PrimaryButton(
                  label: l10n.addIncome,
                  icon: Icons.add_rounded,
                  onPressed: widget.controller.isMutating
                      ? null
                      : widget.onAddIncome,
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              if (widget.controller.incomes.isEmpty)
                EmptyView(message: l10n.noIncomeRecords)
              else
                IncomeList(
                  incomes: widget.controller.incomes,
                  createdAtLabel: l10n.createdAt,
                  deleteLabel: l10n.deleteIncome,
                  onDelete: widget.canEdit ? _confirmDelete : null,
                ),
            ],
          ),
        );
      },
    );
  }
}
