import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../models/app_shell_destination.dart';
import '../models/finance_workspace_section.dart';
import 'app_shell_content.dart';
import 'app_shell_identity_context.dart';

class AppShellBody extends StatelessWidget {
  final CurrentCompanyContext contextData;
  final AuthUser? currentUser;
  final AppShellDestination selected;
  final FinanceWorkspaceSection selectedFinanceSection;
  final ValueChanged<FinanceWorkspaceSection> onFinanceSectionSelected;
  final bool showIdentityContext;

  const AppShellBody({
    required this.contextData,
    required this.currentUser,
    required this.selected,
    required this.selectedFinanceSection,
    required this.onFinanceSectionSelected,
    this.showIdentityContext = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(selected.selectedIcon),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.label(context),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(selected.description(context)),
                      ],
                    ),
                  ),
                ],
              ),
              if (showIdentityContext) ...[
                const SizedBox(height: AppSpacing.lg),
                AppShellIdentityContext(
                  user: currentUser,
                  contextData: contextData,
                  compact: true,
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AppShellContent(
            contextData: contextData,
            selected: selected,
            selectedFinanceSection: selectedFinanceSection,
            onFinanceSectionSelected: onFinanceSectionSelected,
          ),
        ),
      ],
    );
  }
}
