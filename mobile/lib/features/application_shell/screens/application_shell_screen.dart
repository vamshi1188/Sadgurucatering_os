import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import 'package:sadguru_catering/features/authentication/controllers/authentication_controller.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../models/application_tab.dart';
import '../widgets/application_bottom_navigation.dart';
import 'events_placeholder_screen.dart';
import 'finance_placeholder_screen.dart';
import 'settings_placeholder_screen.dart';

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
  State<ApplicationShellScreen> createState() =>
      _ApplicationShellScreenState();
}

class _ApplicationShellScreenState extends State<ApplicationShellScreen> {
  ApplicationTab _currentTab = ApplicationTab.dashboard;
  late final DashboardController _dashboardController;

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController(
      DashboardService(widget.apiClient),
    );
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
    final success = await widget.authenticationController.logout();

    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentTab) {
      case ApplicationTab.dashboard:
        return DashboardScreen(controller: _dashboardController);
      case ApplicationTab.events:
        return const EventsPlaceholderScreen();
      case ApplicationTab.finance:
        return const FinancePlaceholderScreen();
      case ApplicationTab.settings:
        return const SettingsPlaceholderScreen();
    }
  }

  @override
  void dispose() {
    _dashboardController.dispose();
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