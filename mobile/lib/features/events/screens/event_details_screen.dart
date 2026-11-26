import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radii.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/errors/app_error_localization.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../localization/app_localizations.dart';
import '../controllers/event_controller.dart';
import '../models/event.dart';
import '../models/event_status.dart';
import '../../income/controllers/income_controller.dart';
import '../../income/screens/create_income_screen.dart';
import '../../income/screens/income_list_screen.dart';
import '../../expenses/controllers/expense_controller.dart';
import '../../expenses/screens/create_expense_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../profitability/controllers/profitability_controller.dart';
import '../../profitability/screens/profitability_screen.dart';

class EventWorkspaceScreen extends StatefulWidget {
  const EventWorkspaceScreen({
    required this.controller,
    required this.eventId,
    this.incomeController,
    this.expenseController,
    this.profitabilityController,
    super.key,
  });

  final EventController controller;
  final int eventId;
  final IncomeController? incomeController;
  final ExpenseController? expenseController;
  final ProfitabilityController? profitabilityController;

  @override
  State<EventWorkspaceScreen> createState() => _EventWorkspaceScreenState();
}

typedef EventDetailsScreen = EventWorkspaceScreen;

class _EventWorkspaceScreenState extends State<EventWorkspaceScreen> {
  int _selectedModule = 0;

  @override
  void dispose() {
    widget.incomeController?.dispose();
    widget.expenseController?.dispose();
    widget.profitabilityController?.dispose();
    super.dispose();
  }

  Future<void> _openCreateIncome() async {
    final incomeController = widget.incomeController;
    if (incomeController == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CreateIncomeScreen(
          controller: incomeController,
          onCreated: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _openCreateExpense() async {
    final expenseController = widget.expenseController;
    if (expenseController == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CreateExpenseScreen(
          controller: expenseController,
          onCreated: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      widget.controller.selectEvent(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventWorkspace),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
            child: Row(
              children: [
                _WorkspaceTab(
                  label: l10n.eventOverview,
                  selected: _selectedModule == 0,
                  onTap: () => setState(() => _selectedModule = 0),
                ),
                _WorkspaceTab(
                  label: l10n.income,
                  selected: _selectedModule == 1,
                  onTap: () => setState(() => _selectedModule = 1),
                ),
                _WorkspaceTab(
                  label: l10n.expenses,
                  selected: _selectedModule == 2,
                  onTap: () => setState(() => _selectedModule = 2),
                ),
                _WorkspaceTab(
                  label: l10n.profitability,
                  selected: _selectedModule == 3,
                  onTap: () => setState(() => _selectedModule = 3),
                ),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return LoadingView(message: l10n.loading);
          }

          final error = widget.controller.error;

          if (widget.controller.selectedEvent == null) {
            if (error != null) {
              return ErrorView(
                message: localizedAppErrorMessage(l10n, error),
                retryLabel: l10n.retry,
                onRetry: error.retryable
                    ? () => widget.controller.selectEvent(widget.eventId)
                    : null,
              );
            }

            return ErrorView(
              message: l10n.eventNotFound,
              retryLabel: l10n.retry,
              onRetry: () => widget.controller.selectEvent(widget.eventId),
            );
          }

          final event = widget.controller.selectedEvent!;

          if (_selectedModule == 0) {
            return _EventDetailsContent(
              event: event,
              controller: widget.controller,
            );
          }

          if (_selectedModule == 1 && widget.incomeController != null) {
            return IncomeListScreen(
              controller: widget.incomeController!,
              onAddIncome: _openCreateIncome,
            );
          }

          if (_selectedModule == 2 && widget.expenseController != null) {
            return ExpenseListScreen(
              controller: widget.expenseController!,
              onAddExpense: _openCreateExpense,
            );
          }

          if (_selectedModule == 3 && widget.profitabilityController != null) {
            return ProfitabilityScreen(
              controller: widget.profitabilityController!,
            );
          }

          return _WorkspaceModulePlaceholder(
            label: _moduleLabel(l10n),
            description: l10n.workspaceModuleComingSoon,
            icon: _moduleIcon(),
          );
        },
      ),
    );
  }

  String _moduleLabel(AppLocalizations l10n) {
    switch (_selectedModule) {
      case 1:
        return l10n.income;
      case 2:
        return l10n.expenses;
      case 3:
        return l10n.profitability;
      default:
        return l10n.eventOverview;
    }
  }

  IconData _moduleIcon() {
    switch (_selectedModule) {
      case 1:
        return Icons.trending_up_rounded;
      case 2:
        return Icons.receipt_long_outlined;
      case 3:
        return Icons.insights_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }
}

class _WorkspaceTab extends StatelessWidget {
  const _WorkspaceTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _WorkspaceModulePlaceholder extends StatelessWidget {
  const _WorkspaceModulePlaceholder({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.extraLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: AppSpacing.medium),
            Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(description, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EventDetailsContent extends StatelessWidget {
  const _EventDetailsContent({required this.event, required this.controller});

  final Event event;
  final EventController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () => controller.selectEvent(event.id),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.extraLarge,
        ),
        children: [
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: Text(
                l10n.errorDeletingEvent,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          _EventHero(event: event),
          const SizedBox(height: AppSpacing.large),
          _EventInformationCard(event: event),
          const SizedBox(height: AppSpacing.medium),
          _EventStatusAction(event: event, controller: controller),
          const SizedBox(height: AppSpacing.medium),
          _EventDeleteAction(event: event, controller: controller),
          const SizedBox(height: AppSpacing.medium),
          _EventMetadataCard(event: event, l10n: l10n),
        ],
      ),
    );
  }
}

class _EventStatusAction extends StatelessWidget {
  const _EventStatusAction({required this.event, required this.controller});

  final Event event;
  final EventController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    EventStatus? nextStatus;
    String? actionLabel;

    switch (event.status) {
      case EventStatus.upcoming:
        nextStatus = EventStatus.running;
        actionLabel = l10n.startEvent;
      case EventStatus.running:
        nextStatus = EventStatus.completed;
        actionLabel = l10n.completeEvent;
      case EventStatus.completed:
        return const SizedBox.shrink();
    }

    final status = nextStatus;
    final label = actionLabel;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: controller.isMutating
            ? null
            : () async {
                await controller.updateStatus(event.id, status);
              },
        child: controller.isMutating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

class _EventDeleteAction extends StatelessWidget {
  const _EventDeleteAction({required this.event, required this.controller});

  final Event event;
  final EventController controller;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteEvent),
          content: Text(l10n.deleteEventConfirmation),
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
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final deleted = await controller.deleteEvent(event.id);

    if (!context.mounted) {
      return;
    }

    if (deleted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: controller.isMutating ? null : () => _confirmDelete(context),
        child: controller.isMutating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.deleteEvent),
      ),
    );
  }
}

class _EventHero extends StatelessWidget {
  const _EventHero({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.large),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateBadge(event.eventDate),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                _StatusBadge(
                  status: event.status,
                  label: _statusLabel(l10n, event.status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return l10n.upcoming;
      case EventStatus.running:
        return l10n.running;
      case EventStatus.completed:
        return l10n.completed;
    }
  }
}

class _EventInformationCard extends StatelessWidget {
  const _EventInformationCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _DetailsCard(
      title: l10n.eventInformation,
      icon: Icons.event_note_outlined,
      children: [
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: l10n.eventDate,
          value: event.eventDate,
        ),
        _DetailRow(
          icon: Icons.location_on_outlined,
          label: l10n.venue,
          value: event.venue,
        ),
        _DetailRow(
          icon: Icons.people_outline_rounded,
          label: l10n.guests,
          value: '${event.guestCount}',
        ),
      ],
    );
  }
}

class _EventMetadataCard extends StatelessWidget {
  const _EventMetadataCard({required this.event, required this.l10n});

  final Event event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      title: l10n.eventRecord,
      icon: Icons.info_outline_rounded,
      children: [
        _DetailRow(
          icon: Icons.tag_outlined,
          label: l10n.eventId,
          value: '${event.id}',
        ),
        _DetailRow(
          icon: Icons.schedule_outlined,
          label: l10n.createdAt,
          value: _formatDateTime(event.createdAt),
        ),
        _DetailRow(
          icon: Icons.update_outlined,
          label: l10n.updatedAt,
          value: _formatDateTime(event.updatedAt),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';

    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    return '$date $time';
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.mutedText),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge(this.date);

  final String date;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(date);

    if (parsed == null) {
      return Container(
        width: 64,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        child: Text(
          date,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: AppColors.secondary,
            child: Text(
              _month(parsed.month),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${parsed.day}',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            _weekday(parsed.weekday),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
        ],
      ),
    );
  }

  String _month(int month) {
    const values = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return values[month - 1];
  }

  String _weekday(int weekday) {
    const values = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return values[weekday - 1];
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final EventStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      EventStatus.upcoming => AppColors.secondary,
      EventStatus.running => Colors.blue.shade700,
      EventStatus.completed => Colors.green.shade700,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
