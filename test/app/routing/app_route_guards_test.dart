import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_route_guards.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:horus_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/logout_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/register_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/usecases/clear_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_cubit.dart';
import 'package:horus_system/features/company/presentation/pages/company_entry_page.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  const companyContext = CurrentCompanyContext(
    company: Company(id: 'company-1', name: 'Test Company'),
    role: CompanyRole.admin,
  );

  testWidgets(
    'reloads company context when authenticated route starts from empty state',
    (tester) async {
      final companyRepository = _FakeCompanyContextRepository(
        contexts: const [companyContext],
      );
      final currentCompanyCubit = CurrentCompanyCubit(
        loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
          companyRepository,
        ),
        selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(
          companyRepository,
        ),
        refreshSelectedCompanyContextUseCase:
            RefreshSelectedCompanyContextUseCase(companyRepository),
        clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
          companyRepository,
        ),
      );
      final authRepository = _FakeAuthRepository();
      final authCubit = AuthCubit(
        registerUseCase: RegisterUseCase(authRepository),
        loginUseCase: LoginUseCase(authRepository),
        logoutUseCase: LogoutUseCase(authRepository),
        getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
      );

      addTearDown(currentCompanyCubit.close);
      addTearDown(authCubit.close);

      await currentCompanyCubit.clearCurrentCompanyContext();
      await authCubit.login(email: 'member@example.com', password: 'password');

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<CurrentCompanyCubit>.value(value: currentCompanyCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CompanyRequiredRouteGuard(
              builder: (_) =>
                  const SizedBox(key: Key('company-required-content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(companyRepository.loadCalls, 1);
      expect(find.byKey(const Key('company-required-content')), findsOneWidget);
      expect(find.byType(CompanyEntryPage), findsNothing);
    },
  );
}

class _FakeCompanyContextRepository implements CompanyContextRepository {
  final List<CurrentCompanyContext> contexts;
  int loadCalls = 0;

  _FakeCompanyContextRepository({required this.contexts});

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    loadCalls += 1;
    return Success(contexts);
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    return Success(
      contexts.firstWhere((context) => context.companyId == companyId),
    );
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async {
    return Success(contexts.isEmpty ? null : contexts.first);
  }

  @override
  Future<Result<void>> clearCurrentCompanyContext() async {
    return const Success<void>(null);
  }
}

class _FakeAuthRepository implements AuthRepository {
  static const _user = AuthUser(
    id: 'user-1',
    email: 'member@example.com',
    isEmailConfirmed: true,
  );

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    return const Success(_user);
  }

  @override
  Future<Result<void>> logout() async {
    return const Success<void>(null);
  }

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    return const Success<AuthUser?>(_user);
  }

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    return const Success(_user);
  }
}
