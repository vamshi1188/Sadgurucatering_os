import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radii.dart';
import '../../../core/design/app_spacing.dart';
import '../models/finance_report.dart';

class FinanceSummaryCards extends StatelessWidget {
  const FinanceSummaryCards({
    required this.report,
    required this.incomeLabel,
    required this.expensesLabel,
    required this.profitLabel,
    super.key,
  });

  final FinanceReport report;
  final String incomeLabel;
  final String expensesLabel;
  final String profitLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profitValue = report.profit;
    final profitColor = profitValue.startsWith('-')
        ? AppColors.error
        : profitValue == '0.00'
        ? AppColors.mutedText
        : Colors.green.shade700;
    final metrics = [
      (incomeLabel, report.totalIncome, Colors.green.shade700),
      (expensesLabel, report.totalExpenses, AppColors.primary),
      (profitLabel, profitValue, profitColor),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppSpacing.small;
        final amountStyle = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        );
        final widestAmount = metrics
            .map(
              (metric) => _textWidth(
                '₹ ${formatRupees(metric.$2)}',
                amountStyle,
                MediaQuery.textScalerOf(context),
                Directionality.of(context),
              ),
            )
            .reduce((widest, current) => widest > current ? widest : current);
        final requiredCardWidth = widestAmount + AppSpacing.medium * 2 + 2;
        final columns = math.min(
          metrics.length,
          math.max(
            1,
            ((constraints.maxWidth + spacing) / (requiredCardWidth + spacing))
                .floor(),
          ),
        );
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < metrics.length; index++)
              SizedBox(
                width: columns == 2 && index == metrics.length - 1
                    ? constraints.maxWidth
                    : width,
                child: Card(
                  color: Colors.white,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metrics[index].$1,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.small),
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₹ ${formatRupees(metrics[index].$2)}',
                              maxLines: 1,
                              softWrap: false,
                              style: amountStyle?.copyWith(
                                color: metrics[index].$3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

double _textWidth(
  String text,
  TextStyle? style,
  TextScaler textScaler,
  TextDirection textDirection,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  return painter.width;
}

String formatRupees(String exactAmount) {
  final negative = exactAmount.startsWith('-');
  final unsigned = negative ? exactAmount.substring(1) : exactAmount;
  final decimalIndex = unsigned.indexOf('.');
  final whole = decimalIndex < 0
      ? unsigned
      : unsigned.substring(0, decimalIndex);
  final fraction = decimalIndex < 0 ? '' : unsigned.substring(decimalIndex);
  final grouped = StringBuffer();
  for (var index = 0; index < whole.length; index++) {
    final remaining = whole.length - index;
    if (index > 0 && remaining >= 3 && (remaining - 3) % 2 == 0) {
      grouped.write(',');
    }
    grouped.write(whole[index]);
  }
  return '${negative ? '-' : ''}$grouped$fraction';
}
