import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:horus_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/logout_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/register_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:horus_system/features/auth/presentation/cubit/auth_state.dart';
import 'package:horus_system/features/auth/presentation/pages/auth_gate.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'invalid credentials are surfaced after AuthGate loading transition',
    (tester) async {
      final repository = _InvalidLoginAuthRepository();
      final cubit = _TestAuthCubit(repository);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: cubit,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AuthGate(),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'old-password');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(repository.loginCalls, 1);
      expect(find.text('Incorrect email or password.'), findsOneWidget);
    },
  );
}

class _TestAuthCubit extends AuthCubit {
  _TestAuthCubit(_InvalidLoginAuthRepository repository)
    : super(
        registerUseCase: RegisterUseCase(repository),
        loginUseCase: LoginUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        getCurrentUserUseCase: GetCurrentUserUseCase(repository),
      ) {
    emit(const AuthUnauthenticated());
  }
}

class _InvalidLoginAuthRepository implements AuthRepository {
  int loginCalls = 0;

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return const FailureResult<AuthUser>(
      AuthFailure(code: FailureCodes.authInvalidCredentials),
    );
  }

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    throw UnsupportedError('register is not used in this test');
  }

  @override
  Future<Result<void>> logout() async {
    throw UnsupportedError('logout is not used in this test');
  }

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    return const Success<AuthUser?>(null);
  }
}
