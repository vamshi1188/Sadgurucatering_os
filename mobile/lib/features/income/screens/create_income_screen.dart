import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/income_controller.dart';

class CreateIncomeScreen extends StatefulWidget {
  const CreateIncomeScreen({
    required this.controller,
    this.onCreated,
    super.key,
  });

  final IncomeController controller;
  final VoidCallback? onCreated;

  @override
  State<CreateIncomeScreen> createState() => _CreateIncomeScreenState();
}

class _CreateIncomeScreenState extends State<CreateIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.controller.createIncome(
      description: _descriptionController.text.trim(),
      amount: _amountController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      if (widget.onCreated != null) {
        widget.onCreated!();
      } else {
        Navigator.of(context).pop();
      }
      return;
    }

    final error = widget.controller.error;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(localizedAppErrorMessage(l10n, error))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.addIncome)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: [
                AppTextField(
                  controller: _descriptionController,
                  label: l10n.description,
                  enabled: !widget.controller.isMutating,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.requiredDescription;
                    }
                    if (value.trim().length > 255) {
                      return l10n.invalidDescription;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                AppTextField(
                  controller: _amountController,
                  label: l10n.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: !widget.controller.isMutating,
                  validator: (value) {
                    final amount = value?.trim() ?? '';
                    if (!RegExp(r'^(?:0*[1-9]\d*)(?:\.\d{1,2})?$')
                        .hasMatch(amount)) {
                      return l10n.invalidAmount;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.large),
                PrimaryButton(
                  label: l10n.save,
                  icon: Icons.save_outlined,
                  isLoading: widget.controller.isMutating,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
