import 'dart:typed_data';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/company_brand_profile.dart';

enum CompanyBrandingNotice { profileSaved, logoSaved, logoRemoved }

sealed class CompanyBrandingState {
  const CompanyBrandingState();
}

final class CompanyBrandingInitial extends CompanyBrandingState {
  const CompanyBrandingInitial();
}

final class CompanyBrandingLoading extends CompanyBrandingState {
  const CompanyBrandingLoading();
}

final class CompanyBrandingReady extends CompanyBrandingState {
  final CompanyBrandProfile profile;
  final Uint8List? logoBytes;
  final Failure? failure;
  final CompanyBrandingNotice? notice;

  const CompanyBrandingReady({
    required this.profile,
    this.logoBytes,
    this.failure,
    this.notice,
  });
}

final class CompanyBrandingSaving extends CompanyBrandingState {
  final CompanyBrandProfile? profile;
  final Uint8List? logoBytes;

  const CompanyBrandingSaving({this.profile, this.logoBytes});
}

final class CompanyBrandingFailure extends CompanyBrandingState {
  final Failure failure;

  const CompanyBrandingFailure(this.failure);
}
