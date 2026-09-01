import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../datasources/company_invitation_delivery_remote_data_source.dart';

final class CompanyCommandFailureMapper {
  const CompanyCommandFailureMapper();

  Failure fromPostgrest(PostgrestException error) => fromCode(error.message);

  Failure fromDelivery(CompanyInvitationDeliveryException error) =>
      fromCode(error.code);

  Failure fromCode(String code) {
    return switch (code) {
      CompanyFailureCodes.authRequired || 'company_membership_auth_required' =>
        const AuthFailure(code: CompanyFailureCodes.authRequired),
      CompanyFailureCodes.invitationPermissionDenied => const PermissionFailure(
        code: CompanyFailureCodes.invitationPermissionDenied,
      ),
      CompanyFailureCodes.invitationEmailInvalid => const ValidationFailure(
        code: CompanyFailureCodes.invitationEmailInvalid,
      ),
      CompanyFailureCodes.invitationRoleNotAllowed => const PermissionFailure(
        code: CompanyFailureCodes.invitationRoleNotAllowed,
      ),
      'company_invitation_token_invalid' ||
      CompanyFailureCodes.invitationInvalid => const NotFoundFailure(
        code: CompanyFailureCodes.invitationInvalid,
      ),
      CompanyFailureCodes.invitationExpired => const ConflictFailure(
        code: CompanyFailureCodes.invitationExpired,
      ),
      CompanyFailureCodes.invitationRevoked => const ConflictFailure(
        code: CompanyFailureCodes.invitationRevoked,
      ),
      CompanyFailureCodes.invitationAlreadyAccepted => const ConflictFailure(
        code: CompanyFailureCodes.invitationAlreadyAccepted,
      ),
      CompanyFailureCodes.invitationAlreadyPending => const ConflictFailure(
        code: CompanyFailureCodes.invitationAlreadyPending,
      ),
      CompanyFailureCodes.invitationEmailMismatch => const PermissionFailure(
        code: CompanyFailureCodes.invitationEmailMismatch,
      ),
      CompanyFailureCodes.invitationEmailNotVerified => const AuthFailure(
        code: CompanyFailureCodes.invitationEmailNotVerified,
      ),
      CompanyFailureCodes.invitationDeliveryFailed => const ServerFailure(
        code: CompanyFailureCodes.invitationDeliveryFailed,
      ),
      CompanyFailureCodes.invitationDeliveryConfirmationUnknown ||
      'company_invitation_delivery_confirmation_invalid' => const ServerFailure(
        code: CompanyFailureCodes.invitationDeliveryConfirmationUnknown,
      ),
      CompanyFailureCodes.invitationDeliveryNotConfigured =>
        const ServerFailure(
          code: CompanyFailureCodes.invitationDeliveryNotConfigured,
        ),
      CompanyFailureCodes.memberAlreadyActive => const ConflictFailure(
        code: CompanyFailureCodes.memberAlreadyActive,
      ),
      CompanyFailureCodes.memberInactive => const ConflictFailure(
        code: CompanyFailureCodes.memberInactive,
      ),
      CompanyFailureCodes.memberNotFound => const NotFoundFailure(
        code: CompanyFailureCodes.memberNotFound,
      ),
      CompanyFailureCodes.memberRoleChangeNotAllowed => const PermissionFailure(
        code: CompanyFailureCodes.memberRoleChangeNotAllowed,
      ),
      CompanyFailureCodes.memberStatusChangeNotAllowed =>
        const PermissionFailure(
          code: CompanyFailureCodes.memberStatusChangeNotAllowed,
        ),
      CompanyFailureCodes.ownershipCommandRequired => const PermissionFailure(
        code: CompanyFailureCodes.ownershipCommandRequired,
      ),
      CompanyFailureCodes.ownershipTransferNotAllowed =>
        const PermissionFailure(
          code: CompanyFailureCodes.ownershipTransferNotAllowed,
        ),
      CompanyFailureCodes.lastOwnerRequired => const ConflictFailure(
        code: CompanyFailureCodes.lastOwnerRequired,
      ),
      CompanyFailureCodes.notFound => const NotFoundFailure(
        code: CompanyFailureCodes.notFound,
      ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }

  Failure fromUnexpected(Object _) => const UnexpectedFailure();
}
