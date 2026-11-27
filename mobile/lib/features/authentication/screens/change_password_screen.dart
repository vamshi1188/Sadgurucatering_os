import 'package:flutter/material.dart';

import '../../../core/errors/app_error_localization.dart';
import '../../../core/utils/password_validation.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/authentication_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({required this.controller, super.key});

  final AuthenticationController controller;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.controller.changePassword(
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
    );
    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePassword)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) => Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    l10n.changePassword,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _currentPassword,
                    enabled: !widget.controller.isLoading,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.currentPassword,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? l10n.enterPassword
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPassword,
                    enabled: !widget.controller.isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.newPassword,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? l10n.showPassword
                            : l10n.hidePassword,
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) => !isValidPasswordLength(value)
                        ? l10n.passwordMinLength
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmation,
                    enabled: !widget.controller.isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value != _newPassword.text
                        ? l10n.passwordMismatch
                        : null,
                  ),
                  if (widget.controller.error case final error?) ...[
                    const SizedBox(height: 16),
                    Text(
                      localizedAppErrorMessage(l10n, error),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: widget.controller.isLoading ? null : _submit,
                    child: widget.controller.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.changePassword),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
