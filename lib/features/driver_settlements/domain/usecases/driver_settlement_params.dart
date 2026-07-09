import '../../../company/domain/entities/current_company_context.dart';

class GetDriverSettlementsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String? driverId;
  final bool includeVoided;

  const GetDriverSettlementsParams({
    required this.currentCompanyContext,
    this.driverId,
    this.includeVoided = false,
  });
}

class GetDriverSettlementDetailsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String settlementId;

  const GetDriverSettlementDetailsParams({
    required this.currentCompanyContext,
    required this.settlementId,
  });
}

class DriverSettlementCalculationParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double grossSalary;
  final double salaryDeductionsTotal;
  final double balanceDeductionApplied;
  final double settlementDeductionsTotal;
  final String? notes;

  const DriverSettlementCalculationParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.periodStart,
    required this.periodEnd,
    this.grossSalary = 0,
    this.salaryDeductionsTotal = 0,
    this.balanceDeductionApplied = 0,
    this.settlementDeductionsTotal = 0,
    this.notes,
  });
}

class CreateDriverSettlementDraftParams extends DriverSettlementCalculationParams {
  const CreateDriverSettlementDraftParams({
    required super.currentCompanyContext,
    required super.driverId,
    required super.periodStart,
    required super.periodEnd,
    super.grossSalary,
    super.salaryDeductionsTotal,
    super.balanceDeductionApplied,
    super.settlementDeductionsTotal,
    super.notes,
  });
}

class FinalizeDriverSettlementParams {
  final CurrentCompanyContext currentCompanyContext;
  final String settlementId;

  const FinalizeDriverSettlementParams({
    required this.currentCompanyContext,
    required this.settlementId,
  });
}

class VoidDriverSettlementParams {
  final CurrentCompanyContext currentCompanyContext;
  final String settlementId;
  final String reason;

  const VoidDriverSettlementParams({
    required this.currentCompanyContext,
    required this.settlementId,
    required this.reason,
  });
}
