import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/fleet_license_document.dart';
import '../../domain/entities/fleet_license_document_target.dart';

const Object _notSet = Object();

sealed class FleetLicenseDocumentsState {
  const FleetLicenseDocumentsState();
}

final class FleetLicenseDocumentsInitial extends FleetLicenseDocumentsState {
  const FleetLicenseDocumentsInitial();
}

final class FleetLicenseDocumentsLoading extends FleetLicenseDocumentsState {
  const FleetLicenseDocumentsLoading();
}

final class FleetLicenseDocumentsLoaded extends FleetLicenseDocumentsState {
  final CurrentCompanyContext currentCompanyContext;
  final FleetLicenseDocumentTarget target;
  final FleetLicenseDocument? document;
  final bool canManage;
  final bool isMutating;
  final Failure? failure;

  const FleetLicenseDocumentsLoaded({
    required this.currentCompanyContext,
    required this.target,
    required this.document,
    required this.canManage,
    this.isMutating = false,
    this.failure,
  });

  FleetLicenseDocumentsLoaded copyWith({
    Object? document = _notSet,
    bool? canManage,
    bool? isMutating,
    Object? failure = _notSet,
  }) {
    return FleetLicenseDocumentsLoaded(
      currentCompanyContext: currentCompanyContext,
      target: target,
      document: document == _notSet
          ? this.document
          : document as FleetLicenseDocument?,
      canManage: canManage ?? this.canManage,
      isMutating: isMutating ?? this.isMutating,
      failure: failure == _notSet ? this.failure : failure as Failure?,
    );
  }
}

final class FleetLicenseDocumentsFailure extends FleetLicenseDocumentsState {
  final Failure failure;

  const FleetLicenseDocumentsFailure(this.failure);
}
