import '../../../../core/utils/result.dart';

abstract class PendingCompanyInvitationRepository {
  Future<Result<void>> storeToken(String token);

  Future<Result<String?>> getToken();

  Future<Result<void>> clearToken();
}
