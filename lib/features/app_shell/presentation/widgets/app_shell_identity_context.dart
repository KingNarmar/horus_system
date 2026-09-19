import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/widgets/auth_user_identity_summary.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/presentation/extensions/company_role_localization.dart';

class AppShellIdentityContext extends StatelessWidget {
  final AuthUser? user;
  final CurrentCompanyContext contextData;
  final bool compact;

  const AppShellIdentityContext({
    required this.user,
    required this.contextData,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthUserIdentitySummary(user: user, compact: compact),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.companyWithName(contextData.company.name),
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          l10n.roleWithName(contextData.role.localizedLabel(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
