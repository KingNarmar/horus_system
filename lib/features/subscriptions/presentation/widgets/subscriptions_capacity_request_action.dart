import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_external_links.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../localization/subscriptions_localizations.dart';

/// Routes capacity questions to the existing public support channel (#361).
/// This action never changes or requests a new entitlement in the backend.
final class SubscriptionsCapacityRequestAction extends StatelessWidget {
  const SubscriptionsCapacityRequestAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.capacityRequestTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.capacityRequestDescription),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _openSupport(context),
              icon: const Icon(AppIcons.support),
              label: Text(l10n.capacityRequestButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSupport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.subscriptionsL10n.capacityRequestFailed;
    try {
      final opened = await launchUrl(
        AppExternalLinks.horusSupport,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}
