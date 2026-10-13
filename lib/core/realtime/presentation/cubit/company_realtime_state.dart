import '../../../errors/failure.dart';

final class CompanyRealtimeState {
  final String companyId;
  final int customersRevision;
  final Failure? failure;

  const CompanyRealtimeState({
    required this.companyId,
    this.customersRevision = 0,
    this.failure,
  });
}
