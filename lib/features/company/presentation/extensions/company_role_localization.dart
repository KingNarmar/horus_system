import 'package:flutter/widgets.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_role.dart';

extension CompanyRoleLocalizationX on CompanyRole {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      CompanyRole.owner => context.l10n.roleOwner,
      CompanyRole.admin => context.l10n.roleAdmin,
      CompanyRole.operations => context.l10n.roleOperations,
      CompanyRole.accountant => context.l10n.roleAccountant,
      CompanyRole.viewer => context.l10n.roleViewer,
      CompanyRole.driver => context.l10n.roleDriver,
    };
  }
}
