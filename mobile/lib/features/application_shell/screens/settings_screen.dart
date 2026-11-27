import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radii.dart';
import '../../../core/design/app_spacing.dart';
import '../../../localization/app_localizations.dart';
import '../services/settings_services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.onLocaleChanged,
    this.canManageUsers = false,
    this.onManageUsers,
    this.appInfoProvider = const PackageAppInfoProvider(),
    this.appSharingService,
    this.openSupportEmail = launchUrl,
    super.key,
  });

  final ValueChanged<Locale> onLocaleChanged;
  final bool canManageUsers;
  final VoidCallback? onManageUsers;
  final AppInfoProvider appInfoProvider;
  final AppSharingService? appSharingService;
  final Future<bool> Function(Uri) openSupportEmail;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<AppVersionInfo> _appInfo;
  late final AppSharingService _appSharingService;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _appInfo = widget.appInfoProvider.getAppInfo();
    _appSharingService = widget.appSharingService ?? AppSharingService();
  }

  Future<void> _shareApp() async {
    if (_isSharing) {
      return;
    }
    setState(() => _isSharing = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _appSharingService.shareApp();
    } on ShareAppUnavailableException {
      if (mounted) {
        _showMessage(l10n.shareAppUnavailable);
      }
    } on Exception {
      if (mounted) {
        _showMessage(l10n.shareAppFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _contactSupport() async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri(
      scheme: 'mailto',
      path: 'saivamshik11@gmail.com',
      queryParameters: {
        'subject': l10n.supportEmailSubject,
        'body': l10n.supportEmailBody,
      },
    );
    try {
      if (!await widget.openSupportEmail(uri) && mounted) {
        _showMessage(l10n.supportEmailUnavailable);
      }
    } on Exception {
      if (mounted) {
        _showMessage(l10n.supportEmailUnavailable);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: l10n.appName,
      applicationIcon: const Icon(
        Icons.restaurant_menu_rounded,
        color: AppColors.primary,
        size: 38,
      ),
      children: [Text(l10n.aboutDescription)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        110,
      ),
      children: [
        _SectionHeading(title: l10n.applicationSection),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                ),
                title: Text(l10n.appName),
                subtitle: FutureBuilder<AppVersionInfo>(
                  future: _appInfo,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(l10n.appVersionUnavailable);
                    }
                    if (!snapshot.hasData) {
                      return Text(l10n.loading);
                    }
                    final info = snapshot.requireData;
                    return Text(
                      '${l10n.version} ${info.version} '
                      '(${l10n.build} ${info.buildNumber})',
                    );
                  },
                ),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: const Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.primary,
                ),
                title: Text(l10n.shareApp),
                subtitle: Text(l10n.shareAppDescription),
                trailing: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _isSharing ? null : _shareApp,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        _SectionHeading(title: l10n.preferencesSection),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.medium),
                    Text(
                      l10n.language,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'en', label: Text(l10n.english)),
                      ButtonSegment(value: 'te', label: Text(l10n.telugu)),
                    ],
                    selected: {languageCode},
                    onSelectionChanged: (selection) {
                      widget.onLocaleChanged(Locale(selection.first));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.canManageUsers && widget.onManageUsers != null) ...[
          const SizedBox(height: AppSpacing.large),
          _SectionHeading(title: l10n.administrationSection),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.manage_accounts_outlined,
                color: AppColors.primary,
              ),
              title: Text(l10n.userManagement),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onManageUsers,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.large),
        _SectionHeading(title: l10n.supportSection),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.email_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.contactSupport),
                trailing: const Icon(Icons.chevron_right),
                onTap: _contactSupport,
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: const Icon(
                  Icons.business_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.aboutApp),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAboutDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      left: AppSpacing.small,
      bottom: AppSpacing.small,
    ),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AppColors.mutedText, fontWeight: FontWeight.w700),
    ),
  );
}
