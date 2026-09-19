import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_routes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:horus_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/logout_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/register_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:horus_system/features/company/presentation/pages/company_entry_page.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('shows signed-in identity and both company entry paths', (
    tester,
  ) async {
    await _pumpEntry(tester);

    expect(find.text('Signed in as'), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Choose how to continue'), findsOneWidget);
    expect(find.text('Create company'), findsOneWidget);
    expect(find.text('Company invitation'), findsOneWidget);
  });

  testWidgets('create company action opens company creation route', (
    tester,
  ) async {
    await _pumpEntry(tester);

    await tester.tap(find.text('Create company'));
    await tester.pumpAndSettle();

    expect(find.text('creation-route'), findsOneWidget);
  });

  testWidgets('invitation action opens invitation route', (tester) async {
    await _pumpEntry(tester);

    await tester.tap(find.text('Company invitation'));
    await tester.pumpAndSettle();

    expect(find.text('invitation-route'), findsOneWidget);
  });

  testWidgets('Arabic locale renders entry choices RTL', (tester) async {
    await _pumpEntry(tester, locale: const Locale('ar'));

    final createCompany = find.text('إنشاء شركة');
    expect(createCompany, findsOneWidget);
    expect(Directionality.of(tester.element(createCompany)), TextDirection.rtl);
    expect(find.text('تم تسجيل الدخول باسم'), findsOneWidget);
  });
}

Future<void> _pumpEntry(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  final authCubit = _createAuthCubit();
  addTearDown(authCubit.close);
  await authCubit.checkCurrentUser();

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          AppRoutes.companyCreation: (_) =>
              const Scaffold(body: Text('creation-route')),
          AppRoutes.companyInvitation: (_) =>
              const Scaffold(body: Text('invitation-route')),
        },
        home: const CompanyEntryPage(),
      ),
    ),
  );
}

const _user = AuthUser(
  id: 'user-1',
  email: 'user@example.com',
  phone: '+971500000000',
  fullName: 'Test User',
  isEmailConfirmed: true,
);

AuthCubit _createAuthCubit() {
  final repository = _FakeAuthRepository();
  return AuthCubit(
    registerUseCase: RegisterUseCase(repository),
    loginUseCase: LoginUseCase(repository),
    logoutUseCase: LogoutUseCase(repository),
    getCurrentUserUseCase: GetCurrentUserUseCase(repository),
  );
}

final class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthUser?>> getCurrentUser() async =>
      const Success<AuthUser?>(_user);

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async => const Success(_user);

  @override
  Future<Result<void>> logout() async => const Success<void>(null);

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async => const Success(_user);
}
