import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/constants/app_sizes.dart';
import 'package:horus_system/core/theme/app_theme.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/auth_user.dart';
import 'package:horus_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/logout_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/register_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:horus_system/features/auth/presentation/pages/register_page.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'password errors refresh and wrap on narrow mobile in ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repository = _FakeAuthRepository();
        final cubit = AuthCubit(
          registerUseCase: RegisterUseCase(repository),
          loginUseCase: LoginUseCase(repository),
          logoutUseCase: LogoutUseCase(repository),
          getCurrentUserUseCase: GetCurrentUserUseCase(repository),
        );
        addTearDown(cubit.close);

        await tester.pumpWidget(
          BlocProvider<AuthCubit>.value(
            value: cubit,
            child: MaterialApp(
              theme: AppTheme.light,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const RegisterPage(),
            ),
          ),
        );

        final l10n = locale.languageCode == 'ar'
            ? AppLocalizationsAr()
            : AppLocalizationsEn();
        final passwordField = find.byType(TextFormField).last;
        final submitButton = find.text(l10n.createAccountButton);

        expect(
          tester.widget<TextFormField>(passwordField).autovalidateMode,
          AutovalidateMode.onUserInteractionIfError,
        );
        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: passwordField,
                  matching: find.byType(TextField),
                ),
              )
              .decoration
              ?.errorMaxLines,
          AppSizes.formErrorMaxLines,
        );

        await tester.enterText(passwordField, List.filled(73, 'A').join());
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(find.text(l10n.passwordMaxLengthBytes), findsOneWidget);

        // Fixing an error revalidates that field without another submit.
        await tester.enterText(passwordField, List.filled(72, 'A').join());
        await tester.pumpAndSettle();
        expect(find.text(l10n.passwordMaxLengthBytes), findsNothing);

        await tester.enterText(passwordField, List.filled(14, 'A').join());
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();
        expect(find.text(l10n.passwordMinLength), findsOneWidget);

        await tester.enterText(passwordField, List.filled(15, 'A').join());
        await tester.pumpAndSettle();
        expect(find.text(l10n.passwordMinLength), findsNothing);

        // Other required fields stay empty: invalid submissions never reach Data.
        expect(repository.registerCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

final class _FakeAuthRepository implements AuthRepository {
  int registerCalls = 0;

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    throw UnsupportedError('Registration is not expected in validation tests');
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    throw UnsupportedError('Login is not used in this test');
  }

  @override
  Future<Result<void>> logout() async {
    throw UnsupportedError('Logout is not used in this test');
  }

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    return const Success<AuthUser?>(null);
  }
}
