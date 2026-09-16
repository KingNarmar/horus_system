import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/driver_compensation_revision.dart';
import '../../domain/policies/driver_compensation_permission_policy.dart';

sealed class DriverCompensationState {
  const DriverCompensationState();
}

final class DriverCompensationInitial extends DriverCompensationState {
  const DriverCompensationInitial();
}

final class DriverCompensationLoading extends DriverCompensationState {
  final String driverId;

  const DriverCompensationLoading({required this.driverId});
}

final class DriverCompensationFailure extends DriverCompensationState {
  final Failure failure;

  const DriverCompensationFailure(this.failure);
}

final class DriverCompensationLoaded extends DriverCompensationState {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final BusinessDate businessDate;
  final List<DriverCompensationRevision> history;
  final DriverCompensationRevision? currentRevision;
  final Failure? currentResolutionFailure;
  final bool isSaving;
  final String? pendingRevisionId;
  final Failure? mutationFailure;

  const DriverCompensationLoaded({
    required this.currentCompanyContext,
    required this.driverId,
    required this.businessDate,
    required this.history,
    required this.currentRevision,
    required this.currentResolutionFailure,
    this.isSaving = false,
    this.pendingRevisionId,
    this.mutationFailure,
  });

  bool get canManage =>
      DriverCompensationPermissionPolicy.canManage(currentCompanyContext.role);

  bool get canAccessContractDocument =>
      DriverCompensationPermissionPolicy.canAccessContractDocument(
        currentCompanyContext.role,
      );

  DriverCompensationLoaded copyWith({
    bool? isSaving,
    String? pendingRevisionId,
    bool clearPendingRevisionId = false,
    Failure? mutationFailure,
    bool clearMutationFailure = false,
  }) {
    return DriverCompensationLoaded(
      currentCompanyContext: currentCompanyContext,
      driverId: driverId,
      businessDate: businessDate,
      history: history,
      currentRevision: currentRevision,
      currentResolutionFailure: currentResolutionFailure,
      isSaving: isSaving ?? this.isSaving,
      pendingRevisionId: clearPendingRevisionId
          ? null
          : pendingRevisionId ?? this.pendingRevisionId,
      mutationFailure: clearMutationFailure
          ? null
          : mutationFailure ?? this.mutationFailure,
    );
  }
}
