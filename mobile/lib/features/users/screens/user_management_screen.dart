import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../../../core/utils/password_validation.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/user_management_controller.dart';
import '../models/managed_user.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({
    required this.controller,
    required this.currentUserId,
    super.key,
  });

  final UserManagementController controller;
  final int currentUserId;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  Future<void> _openForm({ManagedUser? user}) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<_UserFormResult>(
      context: context,
      builder: (context) => _UserFormDialog(
        user: user,
        isCurrentUser: user?.id == widget.currentUserId,
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    final success = user == null
        ? await widget.controller.createUser(
            username: result.username,
            password: result.password!,
            role: result.role,
          )
        : await widget.controller.updateUser(
            id: user.id,
            username: result.username,
            role: result.role,
            isActive: result.isActive,
          );
    if (success && mounted) {
      _showMessage(user == null ? l10n.userCreated : l10n.userUpdated);
    }
  }

  Future<void> _resetPassword(ManagedUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final password = await showDialog<String>(
      context: context,
      builder: (context) => _PasswordDialog(title: l10n.resetPassword),
    );
    if (password == null || !mounted) {
      return;
    }

    if (await widget.controller.resetPassword(
          id: user.id,
          password: password,
        ) &&
        mounted) {
      _showMessage(l10n.passwordChanged);
    }
  }

  Future<void> _deleteUser(ManagedUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(l10n.deleteUserConfirmation),
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
    if (confirmed != true || !mounted) {
      return;
    }

    if (await widget.controller.deleteUser(user.id) && mounted) {
      _showMessage(l10n.userDeleted);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.userManagement)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.controller.isMutating ? null : () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.createUser),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading && widget.controller.users.isEmpty) {
            return LoadingView(message: l10n.loading);
          }
          final error = widget.controller.error;
          if (error != null && widget.controller.users.isEmpty) {
            return ErrorView(
              message: localizedAppErrorMessage(l10n, error),
              retryLabel: l10n.retry,
              onRetry: error.retryable ? widget.controller.load : null,
            );
          }
          if (widget.controller.users.isEmpty) {
            return Center(child: Text(l10n.noUsers));
          }
          return RefreshIndicator(
            onRefresh: widget.controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                AppSpacing.medium,
                AppSpacing.medium,
                100,
              ),
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: Text(
                      localizedAppErrorMessage(l10n, error),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                for (final user in widget.controller.users)
                  _UserCard(
                    user: user,
                    isCurrentUser: user.id == widget.currentUserId,
                    onEdit: () => _openForm(user: user),
                    onResetPassword: () => _resetPassword(user),
                    onDelete: user.id == widget.currentUserId
                        ? null
                        : () => _deleteUser(user),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isCurrentUser,
    required this.onEdit,
    required this.onResetPassword,
    required this.onDelete,
  });

  final ManagedUser user;
  final bool isCurrentUser;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final role = user.role == 'owner' ? l10n.ownerRole : l10n.supervisorRole;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.username,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                      case 'reset':
                        onResetPassword();
                      case 'delete':
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.editUser)),
                    PopupMenuItem(
                      value: 'reset',
                      child: Text(l10n.resetPassword),
                    ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.deleteUser),
                      ),
                  ],
                ),
              ],
            ),
            Text('${l10n.role}: $role'),
            Text(
              '${l10n.accountStatus}: '
              '${user.isActive ? l10n.active : l10n.inactive}',
            ),
            Text(
              '${l10n.createdAt}: ${user.createdAt.toLocal().toString().split(' ').first}',
            ),
            if (isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.small),
                child: Text(
                  l10n.currentUser,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserFormResult {
  const _UserFormResult({
    required this.username,
    required this.role,
    required this.isActive,
    this.password,
  });

  final String username;
  final String role;
  final bool isActive;
  final String? password;
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({required this.user, required this.isCurrentUser});

  final ManagedUser? user;
  final bool isCurrentUser;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late final TextEditingController _username;
  late final TextEditingController _password;
  late String _role;
  late bool _isActive;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user?.username);
    _password = TextEditingController();
    _role = widget.user?.role ?? 'supervisor';
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCreate = widget.user == null;
    return AlertDialog(
      title: Text(isCreate ? l10n.createUser : l10n.editUser),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _username,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.username),
                validator: (value) {
                  final username = value?.trim() ?? '';
                  if (username.length < 3 || username.length > 64) {
                    return l10n.validationError;
                  }
                  return null;
                },
              ),
              if (isCreate) ...[
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.temporaryPassword,
                  ),
                  validator: (value) => !isValidPasswordLength(value)
                      ? l10n.passwordMinLength
                      : null,
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(labelText: l10n.role),
                items: [
                  DropdownMenuItem(value: 'owner', child: Text(l10n.ownerRole)),
                  DropdownMenuItem(
                    value: 'supervisor',
                    child: Text(l10n.supervisorRole),
                  ),
                ],
                onChanged: widget.isCurrentUser
                    ? null
                    : (value) => setState(() => _role = value ?? _role),
              ),
              if (!isCreate) ...[
                const SizedBox(height: AppSpacing.small),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.accountStatus),
                  subtitle: Text(_isActive ? l10n.active : l10n.inactive),
                  value: _isActive,
                  onChanged: widget.isCurrentUser
                      ? null
                      : (value) => setState(() => _isActive = value),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              _UserFormResult(
                username: _username.text.trim(),
                role: _role,
                isActive: _isActive,
                password: isCreate ? _password.text : null,
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.title});

  final String title;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _password,
          autofocus: true,
          obscureText: true,
          decoration: InputDecoration(labelText: l10n.temporaryPassword),
          validator: (value) =>
              !isValidPasswordLength(value) ? l10n.passwordMinLength : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_password.text);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
