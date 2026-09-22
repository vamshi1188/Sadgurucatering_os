import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/event_controller.dart';
import '../models/event.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({
    required this.controller,
    required this.onCreated,
    super.key,
  });

  final EventController controller;
  final ValueChanged<Event>? onCreated;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _guestCountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedDate = selected;
      _dateController.text = _displayDate(selected);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showMessage(AppLocalizations.of(context)!.selectEventDate);
      return;
    }

    final guestCount = int.tryParse(_guestCountController.text.trim());

    if (guestCount == null || guestCount < 0) {
      return;
    }

    final success = await widget.controller.createEvent(
      title: _titleController.text.trim(),
      eventDate: _formatDate(_selectedDate!),
      venue: _venueController.text.trim(),
      guestCount: guestCount,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      final event = widget.controller.selectedEvent;

      if (event != null) {
        widget.onCreated?.call(event);
      }

      return;
    }

    final error = widget.controller.error;

    if (error != null) {
      _showMessage(AppLocalizations.of(context)!.errorCreatingEvent);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _displayDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.createEvent)),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.medium,
                  AppSpacing.medium,
                  AppSpacing.medium,
                  AppSpacing.extraLarge,
                ),
                children: [
                  Text(
                    l10n.createEvent,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    l10n.createEventDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  AppTextField(
                    controller: _titleController,
                    label: l10n.eventTitle,
                    hint: l10n.enterEventTitle,
                    textInputAction: TextInputAction.next,
                    enabled: !widget.controller.isMutating,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.enterEventTitle;
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _DateField(
                    controller: _dateController,
                    label: l10n.eventDate,
                    hint: l10n.selectEventDate,
                    enabled: !widget.controller.isMutating,
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  AppTextField(
                    controller: _venueController,
                    label: l10n.venue,
                    hint: l10n.enterVenue,
                    textInputAction: TextInputAction.next,
                    enabled: !widget.controller.isMutating,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.enterVenue;
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  AppTextField(
                    controller: _guestCountController,
                    label: l10n.guests,
                    hint: l10n.enterGuestCount,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    enabled: !widget.controller.isMutating,
                    validator: (value) {
                      final guestCount = int.tryParse(value?.trim() ?? '');

                      if (guestCount == null || guestCount < 0) {
                        return l10n.invalidGuestCount;
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: l10n.cancel,
                          onPressed: widget.controller.isMutating
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: PrimaryButton(
                          label: l10n.createEvent,
                          icon: Icons.add_rounded,
                          isLoading: widget.controller.isMutating,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('event-date-field'),
      controller: controller,
      readOnly: true,
      enabled: enabled,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return hint;
        }

        return null;
      },
    );
  }
}
