import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../../core/domain/services/company_business_date_provider.dart';
import '../data/datasources/company_business_date_remote_data_source.dart';
import '../data/datasources/company_invitation_delivery_remote_data_source.dart';
import '../data/datasources/company_invitations_remote_data_source.dart';
import '../data/datasources/company_membership_remote_data_source.dart';
import '../data/datasources/company_regional_settings_remote_data_source.dart';
import '../data/datasources/pending_company_invitation_local_data_source.dart';
import '../data/repositories/company_invitations_repository_impl.dart';
import '../data/repositories/company_membership_repository_impl.dart';
import '../data/repositories/company_regional_settings_repository_impl.dart';
import '../data/repositories/pending_company_invitation_repository_impl.dart';
import '../data/services/company_business_date_provider_impl.dart';
import '../data/services/company_invitation_token_codec.dart';
import '../domain/repositories/company_invitations_repository.dart';
import '../domain/repositories/company_membership_repository.dart';
import '../domain/repositories/company_regional_settings_repository.dart';
import '../domain/repositories/pending_company_invitation_repository.dart';
import '../domain/usecases/accept_company_invitation_usecase.dart';
import '../domain/usecases/change_company_member_role_usecase.dart';
import '../domain/usecases/clear_pending_company_invitation_usecase.dart';
import '../domain/usecases/deactivate_company_member_usecase.dart';
import '../domain/usecases/get_company_invitation_preview_usecase.dart';
import '../domain/usecases/get_company_invitations_usecase.dart';
import '../domain/usecases/get_pending_company_invitation_usecase.dart';
import '../domain/usecases/grant_company_ownership_usecase.dart';
import '../domain/usecases/reactivate_company_member_usecase.dart';
import '../domain/usecases/resend_company_invitation_usecase.dart';
import '../domain/usecases/revoke_company_invitation_usecase.dart';
import '../domain/usecases/send_company_invitation_usecase.dart';
import '../domain/usecases/store_pending_company_invitation_usecase.dart';
import '../domain/usecases/transfer_company_ownership_usecase.dart';
import '../domain/usecases/update_company_regional_settings_usecase.dart';
import '../presentation/cubit/company_invitation_acceptance_cubit.dart';
import '../presentation/cubit/company_invitations_cubit.dart';
import '../presentation/cubit/company_member_actions_cubit.dart';

abstract final class CompanyDependencies {
  static CompanyRegionalSettingsRepository createRegionalSettingsRepository() {
    return CompanyRegionalSettingsRepositoryImpl(
      SupabaseCompanyRegionalSettingsRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static CompanyBusinessDateProvider createBusinessDateProvider() {
    return CompanyBusinessDateProviderImpl(
      SupabaseCompanyBusinessDateRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static CompanyInvitationsRepository createInvitationsRepository() {
    final client = SupabaseClientProvider.client;
    return CompanyInvitationsRepositoryImpl(
      remoteDataSource: SupabaseCompanyInvitationsRemoteDataSource(client),
      deliveryRemoteDataSource:
          SupabaseCompanyInvitationDeliveryRemoteDataSource(client),
      tokenCodec: CompanyInvitationTokenCodec(),
    );
  }

  static CompanyMembershipRepository createMembershipRepository() {
    return CompanyMembershipRepositoryImpl(
      remoteDataSource: SupabaseCompanyMembershipRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static PendingCompanyInvitationRepository
  createPendingInvitationRepository() {
    return PendingCompanyInvitationRepositoryImpl(
      localDataSource: SecurePendingCompanyInvitationLocalDataSource(
        const FlutterSecureStorage(),
      ),
    );
  }

  static CompanyInvitationsCubit createInvitationsCubit() {
    final repository = createInvitationsRepository();
    return CompanyInvitationsCubit(
      getInvitationsUseCase: GetCompanyInvitationsUseCase(repository),
      sendInvitationUseCase: SendCompanyInvitationUseCase(repository),
      resendInvitationUseCase: ResendCompanyInvitationUseCase(repository),
      revokeInvitationUseCase: RevokeCompanyInvitationUseCase(repository),
    );
  }

  static CompanyMemberActionsCubit createMemberActionsCubit() {
    final repository = createMembershipRepository();
    return CompanyMemberActionsCubit(
      changeRoleUseCase: ChangeCompanyMemberRoleUseCase(repository),
      deactivateUseCase: DeactivateCompanyMemberUseCase(repository),
      reactivateUseCase: ReactivateCompanyMemberUseCase(repository),
      grantOwnershipUseCase: GrantCompanyOwnershipUseCase(repository),
      transferOwnershipUseCase: TransferCompanyOwnershipUseCase(repository),
    );
  }

  static CompanyInvitationAcceptanceCubit createInvitationAcceptanceCubit() {
    final invitationsRepository = createInvitationsRepository();
    final pendingRepository = createPendingInvitationRepository();
    return CompanyInvitationAcceptanceCubit(
      storePendingUseCase: StorePendingCompanyInvitationUseCase(
        pendingRepository,
      ),
      getPendingUseCase: GetPendingCompanyInvitationUseCase(pendingRepository),
      clearPendingUseCase: ClearPendingCompanyInvitationUseCase(
        pendingRepository,
      ),
      getPreviewUseCase: GetCompanyInvitationPreviewUseCase(
        invitationsRepository,
      ),
      acceptUseCase: AcceptCompanyInvitationUseCase(invitationsRepository),
    );
  }

  static UpdateCompanyRegionalSettingsUseCase
  createUpdateRegionalSettingsUseCase() {
    return UpdateCompanyRegionalSettingsUseCase(
      createRegionalSettingsRepository(),
    );
  }
}
