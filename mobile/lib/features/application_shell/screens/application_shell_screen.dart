import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';

import 'package:sadguru_catering/features/authentication/controllers/authentication_controller.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../events/controllers/event_controller.dart';
import '../../events/models/event.dart';
import '../../events/screens/event_workspace_screen.dart';
import '../../events/screens/create_event_screen.dart';
import '../../events/screens/event_list_screen.dart';
import '../../events/services/event_service.dart';
import '../../finance/controllers/finance_controller.dart';
import '../../finance/screens/finance_screen.dart';
import '../../finance/services/finance_service.dart';
import '../../income/controllers/income_controller.dart';
import '../../income/services/income_service.dart';
import '../../expenses/controllers/expense_controller.dart';
import '../../expenses/services/expense_service.dart';
import '../../profitability/controllers/profitability_controller.dart';
import '../../profitability/services/profitability_service.dart';
import '../../users/controllers/user_management_controller.dart';
import '../../users/screens/user_management_screen.dart';
import '../../users/services/user_management_service.dart';
import '../models/application_tab.dart';
import '../widgets/application_bottom_navigation.dart';
import 'settings_screen.dart';

class ApplicationShellScreen extends StatefulWidget {
  const ApplicationShellScreen({
    required this.authenticationController,
    required this.onLocaleChanged,
    required this.apiClient,
    super.key,
  });

  final AuthenticationController authenticationController;
  final ValueChanged<Locale> onLocaleChanged;
  final ApiClient apiClient;

  @override
  State<ApplicationShellScreen> createState() => _ApplicationShellScreenState();
}

class _ApplicationShellScreenState extends State<ApplicationShellScreen> {
  ApplicationTab _currentTab = ApplicationTab.dashboard;
  late final DashboardController _dashboardController;
  late final EventController _eventController;
  late final FinanceController _financeController;

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController(
      DashboardService(widget.apiClient),
    );
    _eventController = EventController(EventService(widget.apiClient));
    _financeController = FinanceController(FinanceService(widget.apiClient));
  }

  void _selectTab(ApplicationTab tab) {
    if (_currentTab == tab) {
      return;
    }

    setState(() {
      _currentTab = tab;
    });
  }

  Future<void> _logout() async {
    await widget.authenticationController.logout();
  }

  Future<void> _openCreateEvent() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CreateEventScreen(
          controller: _eventController,
          onCreated: (_) {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _openEventDetails(Event event) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EventWorkspaceScreen(
          controller: _eventController,
          eventId: event.id,
          canEdit: widget.authenticationController.state.user?.isOwner ?? false,
          incomeController: IncomeController(
            eventId: event.id,
            service: IncomeService(widget.apiClient),
          ),
          expenseController: ExpenseController(
            eventId: event.id,
            service: ExpenseService(widget.apiClient),
          ),
          profitabilityController: ProfitabilityController(
            eventId: event.id,
            service: ProfitabilityService(widget.apiClient),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentTab) {
      case ApplicationTab.dashboard:
        return DashboardScreen(controller: _dashboardController);
      case ApplicationTab.events:
        return EventListScreen(
          controller: _eventController,
          onCreateEvent:
              widget.authenticationController.state.user?.isOwner == true
              ? _openCreateEvent
              : null,
          onEventTap: _openEventDetails,
        );
      case ApplicationTab.finance:
        return FinanceScreen(controller: _financeController);
      case ApplicationTab.settings:
        return SettingsScreen(
          onLocaleChanged: widget.onLocaleChanged,
          canManageUsers:
              widget.authenticationController.state.user?.isOwner == true,
          onManageUsers: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => UserManagementScreen(
                  controller: UserManagementController(
                    UserManagementService(widget.apiClient),
                  ),
                  currentUserId: widget.authenticationController.state.user!.id,
                ),
              ),
            );
          },
        );
    }
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    _eventController.dispose();
    _financeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'en', label: Text('English')),
              ButtonSegment<String>(value: 'te', label: Text('తెలుగు')),
            ],
            selected: {Localizations.localeOf(context).languageCode},
            onSelectionChanged: (selection) {
              widget.onLocaleChanged(Locale(selection.first));
            },
          ),
          IconButton(
            onPressed: widget.authenticationController.isLoading
                ? null
                : _logout,
            tooltip: l10n.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: ApplicationBottomNavigation(
        currentTab: _currentTab,
        onTabSelected: _selectTab,
      ),
    );
  }
}
