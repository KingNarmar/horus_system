import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_brand_logo_file.dart';
import '../../domain/entities/company_brand_profile.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/failures/company_branding_failure_codes.dart';
import '../../domain/usecases/download_company_brand_logo_usecase.dart';
import '../../domain/usecases/get_company_brand_profile_usecase.dart';
import '../../domain/usecases/remove_company_brand_logo_usecase.dart';
import '../../domain/usecases/update_company_brand_logo_usecase.dart';
import '../../domain/usecases/update_company_brand_profile_usecase.dart';
import '../../domain/usecases/validate_company_brand_logo_usecase.dart';
import 'company_branding_state.dart';

final class CompanyBrandingCubit extends Cubit<CompanyBrandingState> {
  final GetCompanyBrandProfileUseCase _getProfile;
  final UpdateCompanyBrandProfileUseCase _updateProfile;
  final UpdateCompanyBrandLogoUseCase _updateLogo;
  final RemoveCompanyBrandLogoUseCase _removeLogo;
  final DownloadCompanyBrandLogoUseCase _downloadLogo;
  final ValidateCompanyBrandLogoUseCase _validateLogo;
  int _requestGeneration = 0;

  CompanyBrandingCubit({
    required GetCompanyBrandProfileUseCase getProfile,
    required UpdateCompanyBrandProfileUseCase updateProfile,
    required UpdateCompanyBrandLogoUseCase updateLogo,
    required RemoveCompanyBrandLogoUseCase removeLogo,
    required DownloadCompanyBrandLogoUseCase downloadLogo,
    required ValidateCompanyBrandLogoUseCase validateLogo,
  }) : _getProfile = getProfile,
       _updateProfile = updateProfile,
       _updateLogo = updateLogo,
       _removeLogo = removeLogo,
       _downloadLogo = downloadLogo,
       _validateLogo = validateLogo,
       super(const CompanyBrandingInitial());

  Future<Result<CompanyBrandLogoFile>> validateSelection(
    CompanyBrandLogoFile file,
  ) => _validateLogo(file);

  Future<void> load(CurrentCompanyContext companyContext) async {
    final request = ++_requestGeneration;
    emit(const CompanyBrandingLoading());
    final result = await _getProfile(companyContext.companyId);
    if (!_isCurrent(request)) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      emit(CompanyBrandingFailure(failure));
      return;
    }

    final profile = result.dataOrNull!;
    final path = profile.logoPath;
    if (path == null) {
      emit(CompanyBrandingReady(profile: profile));
      return;
    }

    final downloaded = await _downloadLogo(
      DownloadCompanyBrandLogoParams(
        companyId: companyContext.companyId,
        path: path,
      ),
    );
    if (!_isCurrent(request)) return;

    emit(
      CompanyBrandingReady(
        profile: profile,
        logoBytes: downloaded.dataOrNull,
        failure: downloaded.failureOrNull,
      ),
    );
  }

  Future<void> saveProfile({
    required CurrentCompanyContext companyContext,
    required String name,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
    String? address,
    String? taxRegistrationNumber,
  }) async {
    final current = state;
    if (current is! CompanyBrandingReady ||
        current.profile.companyId != companyContext.companyId) {
      return;
    }
    final request = ++_requestGeneration;
    emit(
      CompanyBrandingSaving(
        profile: current.profile,
        logoBytes: current.logoBytes,
      ),
    );
    final result = await _updateProfile(
      UpdateCompanyBrandProfileParams(
        companyContext: companyContext,
        expectedUpdatedAt: current.profile.updatedAt,
        name: name,
        businessType: businessType,
        phone: phone,
        email: email,
        country: country,
        city: city,
        address: address,
        taxRegistrationNumber: taxRegistrationNumber,
      ),
    );
    if (!_isCurrent(request)) return;
    _resolve(
      result: result,
      before: current,
      notice: CompanyBrandingNotice.profileSaved,
    );
  }

  /// Also works immediately after owner onboarding, before context selection.
  /// The company-creation RPC already committed the new owner's membership.
  Future<Result<CompanyBrandProfile>> uploadLogo({
    required CurrentCompanyContext companyContext,
    required CompanyBrandLogoFile logo,
  }) async {
    final current = state;
    if (current is CompanyBrandingSaving) {
      return const FailureResult(
        ConflictFailure(code: CompanyBrandingFailureCodes.profileConflict),
      );
    }
    final ready =
        current is CompanyBrandingReady &&
            current.profile.companyId == companyContext.companyId
        ? current
        : null;
    final request = ++_requestGeneration;
    emit(
      CompanyBrandingSaving(
        profile: ready?.profile,
        logoBytes: ready?.logoBytes,
      ),
    );
    final result = await _updateLogo(
      UpdateCompanyBrandLogoParams(
        companyContext: companyContext,
        expectedLogoPath:
            ready?.profile.logoPath ?? companyContext.company.logoUrl,
        logo: logo,
      ),
    );
    if (!_isCurrent(request)) return result;
    final profile = result.dataOrNull;
    if (profile != null) {
      emit(
        CompanyBrandingReady(
          profile: profile,
          logoBytes: logo.bytes,
          notice: CompanyBrandingNotice.logoSaved,
        ),
      );
    } else if (ready != null) {
      emit(
        CompanyBrandingReady(
          profile: ready.profile,
          logoBytes: ready.logoBytes,
          failure: result.failureOrNull,
        ),
      );
    } else {
      emit(CompanyBrandingFailure(result.failureOrNull!));
    }
    return result;
  }

  Future<void> removeLogo(CurrentCompanyContext companyContext) async {
    final current = state;
    if (current is! CompanyBrandingReady ||
        current.profile.companyId != companyContext.companyId ||
        current.profile.logoPath == null) {
      return;
    }
    final request = ++_requestGeneration;
    emit(
      CompanyBrandingSaving(
        profile: current.profile,
        logoBytes: current.logoBytes,
      ),
    );
    final result = await _removeLogo(
      RemoveCompanyBrandLogoParams(
        companyContext: companyContext,
        expectedLogoPath: current.profile.logoPath,
      ),
    );
    if (!_isCurrent(request)) return;
    _resolve(
      result: result,
      before: current,
      notice: CompanyBrandingNotice.logoRemoved,
      clearLogoBytes: true,
    );
  }

  void _resolve({
    required Result<CompanyBrandProfile> result,
    required CompanyBrandingReady before,
    required CompanyBrandingNotice notice,
    bool clearLogoBytes = false,
  }) {
    emit(
      CompanyBrandingReady(
        profile: result.dataOrNull ?? before.profile,
        logoBytes: result.dataOrNull != null && clearLogoBytes
            ? null
            : before.logoBytes,
        failure: result.failureOrNull,
        notice: result.dataOrNull == null ? null : notice,
      ),
    );
  }

  bool _isCurrent(int request) => !isClosed && request == _requestGeneration;

  @override
  Future<void> close() async {
    ++_requestGeneration;
    await super.close();
  }
}
