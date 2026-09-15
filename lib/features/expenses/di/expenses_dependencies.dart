import '../../../core/data/supabase/supabase_client_provider.dart';
import '../data/datasources/expense_ledger_remote_data_source.dart';
import '../data/repositories/expense_ledger_repository_impl.dart';
import '../domain/repositories/expense_ledger_repository.dart';
import '../domain/usecases/create_expense_ledger_entry_usecase.dart';
import '../domain/usecases/create_trip_expense_usecase.dart';
import '../domain/usecases/get_trip_expense_ledger_entries_usecase.dart';
import '../domain/usecases/void_expense_ledger_entry_usecase.dart';

abstract final class ExpensesDependencies {
  static ExpenseLedgerRepository createRepository() {
    return ExpenseLedgerRepositoryImpl(
      remoteDataSource: SupabaseExpenseLedgerRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static GetTripExpenseLedgerEntriesUseCase
  createGetTripExpenseLedgerEntriesUseCase() {
    return GetTripExpenseLedgerEntriesUseCase(createRepository());
  }

  static CreateTripExpenseUseCase createCreateTripExpenseUseCase() {
    final createLedgerEntryUseCase = CreateExpenseLedgerEntryUseCase(
      createRepository(),
    );
    return CreateTripExpenseUseCase(createLedgerEntryUseCase);
  }

  static VoidExpenseLedgerEntryUseCase createVoidExpenseLedgerEntryUseCase() {
    return VoidExpenseLedgerEntryUseCase(createRepository());
  }
}
