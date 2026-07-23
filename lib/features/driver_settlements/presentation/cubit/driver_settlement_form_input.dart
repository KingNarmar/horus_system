import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/usecases/driver_settlement_usecases.dart';

class DriverSettlementFormInput {
  final String driverId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double grossSalary;
  final double salaryDeductionsTotal;
  final double balanceDeductionApplied;
  final double settlementDeductionsTotal;
  final String? notes;

  const DriverSettlementFormInput({
    required this.driverId,
    required this.periodStart,
    required this.periodEnd,
    required this.grossSalary,
    required this.salaryDeductionsTotal,
    required this.balanceDeductionApplied,
    required this.settlementDeductionsTotal,
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
      grossSalary: grossSalary,
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
      grossSalary: grossSalary,
      salaryDeductionsTotal: salaryDeductionsTotal,
      balanceDeductionApplied: balanceDeductionApplied,
      settlementDeductionsTotal: settlementDeductionsTotal,
      notes: notes,
    );
  }
}
