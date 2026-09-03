import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_timezone_repository.dart';
import 'package:horus_system/features/company/domain/usecases/get_company_timezone_options_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_business_timezone_usecase.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:horus_system/features/company/presentation/cubit/company_timezone_cubit.dart';
import 'package:horus_system/features/company/presentation/helpers/company_timezone_display_option.dart';
import 'package:horus_system/features/company/presentation/widgets/company_timezone_selector.dart';
import 'package:horus_system/features/company/presentation/widgets/company_timezone_settings_card.dart';

void main() {
  testWidgets('owner sees searchable timezone editor and localized current value', (
    tester,
  ) async {
    final cubit = _buildCubit();
    addTearDown(cubit.close);
    await cubit.loadOptions();
    final timezone = CompanyTimezone.tryParse('Asia/Dubai')!;
    final display = CompanyTimezoneDisplayResolver.resolve(
      timezone,
      const Locale('en'),
    ).displayLabel;

    await tester.pumpWidget(
      BlocProvider<CompanyTimezoneCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: CompanyTimezoneSettingsCard(
              currentCompanyContext: _context(CompanyRole.owner),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Business timezone'), findsOneWidget);
    expect(find.text('Current timezone: $display'), findsOneWidget);
    expect(find.byType(CompanyTimezoneSelector), findsOneWidget);
    expect(find.text('Save timezone'), findsOneWidget);
  });

  testWidgets('viewer sees localized current timezone without management controls', (
    tester,
  ) async {
    final cubit = _buildCubit();
    addTearDown(cubit.close);
    final timezone = CompanyTimezone.tryParse('Asia/Dubai')!;
    final display = CompanyTimezoneDisplayResolver.resolve(
      timezone,
      const Locale('en'),
    ).displayLabel;

    await tester.pumpWidget(
      BlocProvider<CompanyTimezoneCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: CompanyTimezoneSettingsCard(
              currentCompanyContext: _context(CompanyRole.viewer),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Business timezone'), findsOneWidget);
    expect(find.text('Current timezone: $display'), findsOneWidget);
    expect(find.byType(CompanyTimezoneSelector), findsNothing);
    expect(find.text('Save timezone'), findsNothing);
  });
}

CompanyTimezoneCubit _buildCubit() {
  final repository = _FakeCompanyTimezoneRepository();
  return CompanyTimezoneCubit(
    getOptionsUseCase: GetCompanyTimezoneOptionsUseCase(repository),
    updateTimezoneUseCase: UpdateCompanyBusinessTimezoneUseCase(repository),
  );
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Horus Transport',
      businessTimezone: 'Asia/Dubai',
    ),
    role: role,
  );
}

final class _FakeCompanyTimezoneRepository
    implements CompanyTimezoneRepository {
  @override
  Future<Result<List<CompanyTimezone>>> getTimezoneOptions() async => Success([
    CompanyTimezone.tryParse('Asia/Dubai')!,
    CompanyTimezone.tryParse('Europe/London')!,
  ]);

  @override
  Future<Result<Company>> updateBusinessTimezone({
    required String companyId,
    required CompanyTimezone businessTimezone,
  }) async {
    return Success(
      Company(
        id: companyId,
        name: 'Horus Transport',
        businessTimezone: businessTimezone.value,
      ),
    );
  }
}
