import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_external_links.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';

class LegalSupportSettingsCard extends StatelessWidget {
  const LegalSupportSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.legalSupportTitle,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.legalSupportDescription),
            const SizedBox(height: AppSpacing.lg),
            _LegalSupportAction(
              icon: AppIcons.privacy,
              label: l10n.privacyPolicy,
              onPressed: () {
                _open(context, AppExternalLinks.horusPrivacyPolicy);
              },
            ),
            _LegalSupportAction(
              icon: AppIcons.terms,
              label: l10n.termsOfService,
              onPressed: () {
                _open(context, AppExternalLinks.horusTerms);
              },
            ),
            _LegalSupportAction(
              icon: AppIcons.support,
              label: l10n.productSupport,
              onPressed: () {
                _open(context, AppExternalLinks.horusSupport);
              },
            ),
            _LegalSupportAction(
              icon: AppIcons.email,
              label: l10n.emailProductSupport,
              onPressed: () {
                _open(context, AppExternalLinks.horusSupportEmail);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.externalLinkOpenFailed)),
      );
    }
  }
}

class _LegalSupportAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _LegalSupportAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(AppIcons.openExternal),
      onTap: onPressed,
    );
  }
}
