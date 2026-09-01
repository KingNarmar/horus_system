import 'package:flutter/material.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../widgets/company_logout_button.dart';

class CompanyEntryPage extends StatelessWidget {
  const CompanyEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: const [
          CompanyLogoutButton(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _CompanyEntryContent(
            maxWidth: AppSizes.mobileMaxContentWidth,
            horizontalPadding: AppSpacing.lg,
          ),
          tablet: _CompanyEntryContent(
            maxWidth: AppSizes.tabletMaxContentWidth,
            horizontalPadding: AppSpacing.xl,
          ),
          desktop: _CompanyEntryContent(
            maxWidth: AppSizes.desktopAuthFormMaxWidth,
            horizontalPadding: AppSpacing.xxl,
          ),
        ),
      ),
    );
  }
}

class _CompanyEntryContent extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;

  const _CompanyEntryContent({
    required this.maxWidth,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.companyCreation),
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.createCompanyTitle),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.companyInvitation),
                    icon: const Icon(AppIcons.invitations),
                    label: Text(l10n.invitationTitle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
