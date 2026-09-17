import '../../../../core/domain/value_objects/business_date.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/usecases/driver_settlement_usecases.dart';

class DriverSettlementFormInput {
  final String driverId;
  final BusinessDate periodStart;
  final BusinessDate periodEnd;
  final String salaryDeductionsTotal;
  final String balanceDeductionApplied;
  final String settlementDeductionsTotal;
  final String? notes;

  const DriverSettlementFormInput({
    required this.driverId,
    required this.periodStart,
    required this.periodEnd,
    this.salaryDeductionsTotal = '',
    this.balanceDeductionApplied = '',
    this.settlementDeductionsTotal = '',
    this.notes,
  });

  DriverSettlementCalculationParams toCalculationParams(
    CurrentCompanyContext currentCompanyContext,
  ) {
    return DriverSettlementCalculationParams(
      currentCompanyContext: currentCompanyContext,
      driverId: driverId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      salaryDeductionsTotal: salaryDeductionsTotal,
      balanceDeductionApplied: balanceDeductionApplied,
      settlementDeductionsTotal: settlementDeductionsTotal,
      notes: notes,
    );
  }

  CreateDriverSettlementDraftParams toCreateDraftParams(
    CurrentCompanyContext currentCompanyContext,
  ) {
    return CreateDriverSettlementDraftParams(
      currentCompanyContext: currentCompanyContext,
      driverId: driverId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      salaryDeductionsTotal: salaryDeductionsTotal,
      balanceDeductionApplied: balanceDeductionApplied,
      settlementDeductionsTotal: settlementDeductionsTotal,
      notes: notes,
    );
  }
}
