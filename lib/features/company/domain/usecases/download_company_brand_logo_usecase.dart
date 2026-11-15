import 'dart:typed_data';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../failures/company_branding_failure_codes.dart';
import '../repositories/company_branding_repository.dart';

final class DownloadCompanyBrandLogoParams {
  final String companyId;
  final String path;

  const DownloadCompanyBrandLogoParams({
    required this.companyId,
    required this.path,
  });
}

final class DownloadCompanyBrandLogoUseCase
    implements UseCase<Uint8List, DownloadCompanyBrandLogoParams> {
  final CompanyBrandingRepository _repository;

  const DownloadCompanyBrandLogoUseCase(this._repository);

  @override
  Future<Result<Uint8List>> call(DownloadCompanyBrandLogoParams params) {
    if (!params.path.startsWith('companies/${params.companyId}/logos/')) {
      return Future.value(const FailureResult(
        ValidationFailure(code: CompanyBrandingFailureCodes.uploadInvalid),
      ));
    }
    return _repository.downloadLogo(
      companyId: params.companyId,
      storagePath: params.path,
    );
  }
}
