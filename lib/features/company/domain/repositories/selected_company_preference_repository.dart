import '../../../../core/utils/result.dart';

/// A per-authenticated-user, per-device preference; never authorization.
abstract interface class SelectedCompanyPreferenceRepository {
  Future<Result<String?>> read(String userId);

  Future<Result<void>> save({
    required String userId,
    required String companyId,
  });
}
