import 'package:flutter/material.dart';

import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/error_view.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/authentication_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    required this.onLocaleChanged,
  });

  final AuthenticationController controller;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.controller.login(
      _passwordController.text,
    );

    if (!mounted || !success) {
      return;
    }

    if (widget.controller.state.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final error = widget.controller.error;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      localization.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localization.welcome,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !widget.controller.isLoading,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: localization.password,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localization.enterPassword;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (error != null) ...[
                      ErrorView(
                        message: localizedAppErrorMessage(localization, error),
                        retryLabel: localization.retry,
                        onRetry: error.retryable ? _login : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      onPressed:
                          widget.controller.isLoading ? null : _login,
                      child: widget.controller.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(localization.login),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      localization.language,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'en',
                          label: Text('English'),
                        ),
                        ButtonSegment<String>(
                          value: 'te',
                          label: Text('తెలుగు'),
                        ),
                      ],
                      selected: {
                        Localizations.localeOf(context).languageCode,
                      },
                      onSelectionChanged: (selection) {
                        widget.onLocaleChanged(
                          Locale(selection.first),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}