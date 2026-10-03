import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_routes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/repositories/password_recovery_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/request_password_recovery_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/password_recovery_cubit.dart';
import 'package:horus_system/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('valid request shows generic anti-enumeration success message', (
    tester,
  ) async {
    final repository = _FakePasswordRecoveryRepository();
    final cubit = PasswordRecoveryCubit(
      requestPasswordRecovery: RequestPasswordRecoveryUseCase(repository),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_TestApp(cubit: cubit));

    await tester.enterText(
      find.byType(TextFormField),
      '  user@example.com  ',
    );
    await tester.tap(find.text('Send recovery email'));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(repository.lastEmail, 'user@example.com');
    expect(find.text('Check your email'), findsOneWidget);
    expect(
      find.text(
        'If an account exists for this email address, password recovery instructions will arrive shortly.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('user@example.com'), findsNothing);
  });

  testWidgets('malformed email is rejected before repository call', (
    tester,
  ) async {
    final repository = _FakePasswordRecoveryRepository();
    final cubit = PasswordRecoveryCubit(
      requestPasswordRecovery: RequestPasswordRecoveryUseCase(repository),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_TestApp(cubit: cubit));

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text('Send recovery email'));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(repository.calls, 0);
  });

  testWidgets('Arabic recovery copy is localized', (tester) async {
    final repository = _FakePasswordRecoveryRepository();
    final cubit = PasswordRecoveryCubit(
      requestPasswordRecovery: RequestPasswordRecoveryUseCase(repository),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        locale: const Locale('ar'),
      ),
    );

    expect(find.text('استعادة كلمة المرور'), findsOneWidget);
    expect(find.text('إرسال رسالة الاستعادة'), findsOneWidget);
    expect(find.text('العودة لتسجيل الدخول'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final PasswordRecoveryCubit cubit;
  final Locale? locale;

  const _TestApp({required this.cubit, this.locale});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PasswordRecoveryCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login')),
        },
        home: const ForgotPasswordPage(),
      ),
    );
  }
}

final class _FakePasswordRecoveryRepository
    implements PasswordRecoveryRepository {
  int calls = 0;
  String? lastEmail;

  @override
  Future<Result<void>> requestPasswordRecovery({required String email}) async {
    calls++;
    lastEmail = email;
    return const Success<void>(null);
  }
}
