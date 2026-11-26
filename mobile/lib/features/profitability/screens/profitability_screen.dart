import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/profitability_controller.dart';
import '../widgets/profitability_summary.dart';

class ProfitabilityScreen extends StatefulWidget {
  const ProfitabilityScreen({required this.controller, super.key});

  final ProfitabilityController controller;

  @override
  State<ProfitabilityScreen> createState() => _ProfitabilityScreenState();
}

class _ProfitabilityScreenState extends State<ProfitabilityScreen> {
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
            widget.controller.profitability == null) {
          return LoadingView(message: l10n.loading);
        }

        final error = widget.controller.error;
        final profitability = widget.controller.profitability;

        if (error != null && profitability == null) {
          return ErrorView(
            message: localizedAppErrorMessage(l10n, error),
            retryLabel: l10n.retry,
            onRetry: error.retryable ? widget.controller.retry : null,
          );
        }

        if (profitability == null) {
          return ErrorView(
            message: l10n.unknownError,
            retryLabel: l10n.retry,
            onRetry: null,
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
              ProfitabilitySummary(profitability: profitability),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  localizedAppErrorMessage(l10n, error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
