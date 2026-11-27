import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../models/expense.dart';
import 'expense_card.dart';

class ExpenseList extends StatelessWidget {
  const ExpenseList({
    required this.expenses,
    required this.createdAtLabel,
    required this.deleteLabel,
    this.onDelete,
    super.key,
  });

  final List<Expense> expenses;
  final String createdAtLabel;
  final String deleteLabel;
  final ValueChanged<Expense>? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final expense in expenses) ...[
          ExpenseCard(
            expense: expense,
            createdAtLabel: createdAtLabel,
            deleteLabel: deleteLabel,
            onDelete: onDelete == null ? null : () => onDelete!(expense),
          ),
          const SizedBox(height: AppSpacing.small),
        ],
      ],
    );
  }
}
