import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../localization/expense_types_localizations.dart';

String expenseTypesFailureMessage(
  Failure failure,
  ExpenseTypesLocalizations l10n,
) {
  return switch (failure.code) {
    FailureCodes.permissionExpenseTypesView => l10n.permissionViewFailure,
    _ => l10n.genericFailure,
  };
}
