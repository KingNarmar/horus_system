import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../widgets/account_deletion_settings_card.dart';

class AccountDeletionPage extends StatelessWidget {
  const AccountDeletionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.accountDeletionTitle)),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: const _AccountDeletionContent(
            maxWidth: AppSizes.mobileMaxContentWidth,
            horizontalPadding: AppSpacing.lg,
          ),
          tablet: const _AccountDeletionContent(
            maxWidth: AppSizes.tabletMaxContentWidth,
            horizontalPadding: AppSpacing.xl,
          ),
          desktop: const _AccountDeletionContent(
            maxWidth: AppSizes.desktopAuthFormMaxWidth,
            horizontalPadding: AppSpacing.xxl,
          ),
        ),
      ),
    );
  }
}

class _AccountDeletionContent extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;

  const _AccountDeletionContent({
    required this.maxWidth,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: const AccountDeletionSettingsCard(),
        ),
      ),
    );
  }
}
