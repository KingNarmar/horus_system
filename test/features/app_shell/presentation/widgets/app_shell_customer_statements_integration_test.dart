import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/routing/app_routes.dart';
import 'package:horus_system/features/app_shell/presentation/models/app_shell_destination.dart';

void main() {
  test('registers customer statements as one company-scoped App Shell module', () {
    expect(
      AppRoutes.companyRequiredRoutes,
      contains(AppRoutes.customerStatements),
    );

    final destinations = appShellDestinations
        .where(
          (destination) =>
              destination.module == AppShellModule.customerStatements,
        )
        .toList(growable: false);

    expect(destinations, hasLength(1));
  });
}
