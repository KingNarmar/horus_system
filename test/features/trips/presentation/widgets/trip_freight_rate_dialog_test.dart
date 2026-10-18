import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/repositories/trip_financial_terms_repository.dart';
import 'package:horus_system/features/trips/domain/usecases/set_trip_freight_rate_usecase.dart';
import 'package:horus_system/features/trips/domain/value_objects/quantity_tons.dart';
import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';
import 'package:horus_system/features/trips/presentation/cubit/trip_freight_rate_cubit.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_freight_rate_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('finance-only dialog has just the rate input in English', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final cubit = TripFreightRateCubit(SetTripFreightRateUseCase(repository));
    await tester.pumpWidget(
      _app(
        cubit,
        role: CompanyRole.accountant,
        locale: const Locale('en'),
      ),
    );
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Edit freight rate'), findsOneWidget);
    expect(find.text('Save rate'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('operation role receives localized denial without data write', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final cubit = TripFreightRateCubit(SetTripFreightRateUseCase(repository));
    await tester.pumpWidget(
      _app(
        cubit,
        role: CompanyRole.operations,
        locale: const Locale('ar'),
      ),
    );

    expect(find.text('تعديل سعر النقل'), findsOneWidget);
    expect(find.text('حفظ السعر'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '12.34');
    await tester.tap(find.text('حفظ السعر'));
    await tester.pumpAndSettle();
    expect(
      find.text('ليس لديك صلاحية تعديل أسعار الرحلة أو المبالغ المالية.'),
      findsOneWidget,
    );
    expect(repository.calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });
}

Widget _app(
  TripFreightRateCubit cubit, {
  required CompanyRole role,
  required Locale locale,
}) {
  return BlocProvider.value(
    value: cubit,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TripFreightRateDialog(
          currentCompanyContext: CurrentCompanyContext(
            company: const Company(
              id: 'company-1',
              name: 'Company',
              baseCurrencyCode: 'AED',
              baseCurrencyFractionDigits: 2,
            ),
            role: role,
          ),
          trip: _trip,
        ),
      ),
    ),
  );
}

final _trip = TripEntity(
  id: 'trip-1',
  companyId: 'company-1',
  tripNumber: TripNumber.tryParse('TRP-2026-000001')!,
  customerId: 'customer-1',
  routeId: 'route-1',
  status: TripStatus.created,
  quantityTons: QuantityTons.tryParse('10'),
  updatedAt: DateTime.utc(2026, 10, 18),
);

final class _FakeRepository implements TripFinancialTermsRepository {
  int calls = 0;

  @override
  Future<Result<TripEntity>> setFreightRate({
    required String companyId,
    required String tripId,
    required Money agreedFreightRatePerTon,
    required CurrencyConfiguration financialConfiguration,
    required DateTime expectedUpdatedAt,
  }) async {
    calls += 1;
    return Success(_trip);
  }
}
