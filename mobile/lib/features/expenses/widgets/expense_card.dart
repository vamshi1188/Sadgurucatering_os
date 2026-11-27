import 'package:flutter/material.dart';

import '../../../core/design/app_radii.dart';
import '../../../core/design/app_spacing.dart';
import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    required this.expense,
    required this.createdAtLabel,
    required this.deleteLabel,
    required this.onDelete,
    super.key,
  });

  final Expense expense;
  final String createdAtLabel;
  final String deleteLabel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text('$createdAtLabel: ${expense.createdAt.toLocal()}'),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  expense.amount,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: deleteLabel,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
