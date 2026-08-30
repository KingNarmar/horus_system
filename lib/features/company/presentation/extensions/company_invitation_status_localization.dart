import 'package:flutter/widgets.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_invitation_status.dart';

extension CompanyInvitationStatusLocalizationX on CompanyInvitationStatus {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      CompanyInvitationStatus.pending => context.l10n.invitationStatusPending,
      CompanyInvitationStatus.accepted => context.l10n.invitationStatusAccepted,
      CompanyInvitationStatus.expired => context.l10n.invitationStatusExpired,
      CompanyInvitationStatus.revoked => context.l10n.invitationStatusRevoked,
    };
  }
}
