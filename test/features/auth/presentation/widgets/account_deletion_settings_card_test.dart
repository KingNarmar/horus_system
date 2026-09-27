import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/account_deletion_status.dart';
import 'package:horus_system/features/auth/domain/repositories/account_deletion_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/cancel_account_deletion_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/get_account_deletion_status_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/request_account_deletion_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/account_deletion_cubit.dart';
import 'package:horus_system/features/auth/presentation/widgets/account_deletion_settings_card.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('pending request shows cancel action', (tester) async {
    final cubit = _buildCubit(const Success<AccountDeletionStatus>(_pending));
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(_app(cubit));

    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text('Cancel deletion request'), findsOneWidget);
    expect(find.text('Request account deletion'), findsNothing);
  });

  testWidgets('request requires explicit confirmation', (tester) async {
    final repository = _FakeRepository(
      const Success<AccountDeletionStatus>(_none),
    );
    final cubit = _buildCubitWithRepository(repository);
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(_app(cubit));
    await tester.tap(find.text('Request account deletion'));
    await tester.pumpAndSettle();

    expect(find.text('Request account deletion?'), findsOneWidget);
    expect(repository.requestCalls, 0);

    await tester.tap(find.text('Request deletion'));
    await tester.pumpAndSettle();

    expect(repository.requestCalls, 1);
  });
}

const _none = AccountDeletionStatus(state: AccountDeletionRequestState.none);

const _pending = AccountDeletionStatus(
  state: AccountDeletionRequestState.pending,
);

Widget _app(AccountDeletionCubit cubit) {
  return BlocProvider<AccountDeletionCubit>.value(
    value: cubit,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AccountDeletionSettingsCard()),
    ),
  );
}

AccountDeletionCubit _buildCubit(Result<AccountDeletionStatus> status) {
  return _buildCubitWithRepository(_FakeRepository(status));
}

AccountDeletionCubit _buildCubitWithRepository(
  AccountDeletionRepository repository,
) {
  return AccountDeletionCubit(
    getStatus: GetAccountDeletionStatusUseCase(repository),
    requestDeletion: RequestAccountDeletionUseCase(repository),
    cancelDeletion: CancelAccountDeletionUseCase(repository),
  );
}

final class _FakeRepository implements AccountDeletionRepository {
  _FakeRepository(this.status);

  final Result<AccountDeletionStatus> status;
  int requestCalls = 0;

  @override
  Future<Result<AccountDeletionStatus>> getStatus() async => status;

  @override
  Future<Result<AccountDeletionStatus>> requestDeletion() async {
    requestCalls++;
    return const Success<AccountDeletionStatus>(_pending);
  }

  @override
  Future<Result<AccountDeletionStatus>> cancelDeletion() async {
    return const Success<AccountDeletionStatus>(_none);
  }
}
