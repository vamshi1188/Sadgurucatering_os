import 'package:flutter/material.dart';

import '../models/income.dart';
import 'income_card.dart';

class IncomeList extends StatelessWidget {
  const IncomeList({
    required this.incomes,
    required this.createdAtLabel,
    required this.deleteLabel,
    this.onDelete,
    super.key,
  });

  final List<Income> incomes;
  final String createdAtLabel;
  final String deleteLabel;
  final ValueChanged<Income>? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final income in incomes) ...[
          IncomeCard(
            income: income,
            createdAtLabel: createdAtLabel,
            deleteLabel: deleteLabel,
            onDelete: onDelete == null ? null : () => onDelete!(income),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
