import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../localization/expense_types_localizations.dart';

String expenseTypesFailureMessage(
  Failure failure,
  ExpenseTypesLocalizations l10n,
) {
  return switch (failure.code) {
    FailureCodes.permissionExpenseTypesView => l10n.permissionViewFailure,
    FailureCodes.permissionExpenseTypesManagement =>
      l10n.permissionManageFailure,
    FailureCodes.validationExpenseTypeNameRequired => l10n.nameRequired,
    FailureCodes.conflictExpenseTypeDuplicateName => l10n.duplicateNameFailure,
    FailureCodes.expenseTypeNotFound => l10n.notFoundFailure,
    _ => l10n.genericFailure,
  };
}
