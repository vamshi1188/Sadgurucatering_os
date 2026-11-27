import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../widgets/expense_list.dart';
import '../widgets/expense_summary.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({
    required this.controller,
    this.onAddExpense,
    this.canEdit = true,
    super.key,
  });

  final ExpenseController controller;
  final VoidCallback? onAddExpense;
  final bool canEdit;

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _confirmDelete(Expense expense) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteExpense),
        content: Text(l10n.deleteExpenseConfirmation),
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
      await widget.controller.deleteExpense(expense.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading && widget.controller.expenses.isEmpty) {
          return LoadingView(message: l10n.loading);
        }

        final error = widget.controller.error;
        if (error != null && widget.controller.expenses.isEmpty) {
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
              ExpenseSummary(
                label: l10n.totalExpenses,
                amount: widget.controller.totalExpenses,
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  localizedAppErrorMessage(l10n, error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              if (widget.onAddExpense != null) ...[
                PrimaryButton(
                  label: l10n.addExpense,
                  icon: Icons.add_rounded,
                  onPressed: widget.controller.isMutating
                      ? null
                      : widget.onAddExpense,
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              if (widget.controller.expenses.isEmpty)
                EmptyView(message: l10n.noExpenseRecords)
              else
                ExpenseList(
                  expenses: widget.controller.expenses,
                  createdAtLabel: l10n.createdAt,
                  deleteLabel: l10n.deleteExpense,
                  onDelete: widget.canEdit ? _confirmDelete : null,
                ),
            ],
          ),
        );
      },
    );
  }
}
