import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
import 'package:horus_system/core/realtime/domain/repositories/company_data_changes_repository.dart';
import 'package:horus_system/core/realtime/domain/usecases/watch_company_data_changes_usecase.dart';
import 'package:horus_system/core/realtime/presentation/cubit/company_realtime_cubit.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/customers/presentation/widgets/customers_realtime_boundary.dart';

void main() {
  testWidgets('switching tenant disposes old visible-screen subscription', (
    tester,
  ) async {
    final repository = _TrackingRepository();
    final cubits = <CompanyRealtimeCubit>[];
    CompanyRealtimeCubit factory() {
      final cubit = CompanyRealtimeCubit(
        watchChanges: WatchCompanyDataChangesUseCase(repository),
      );
      cubits.add(cubit);
      return cubit;
    }

    Widget app(String companyId) => MaterialApp(
      home: CustomersRealtimeBoundary(
        currentCompanyContext: _context(companyId),
        realtimeCubitFactory: factory,
        child: const SizedBox.shrink(),
      ),
    );

    await tester.pumpWidget(app('company-a'));
    expect(repository.watched, ['company-a']);
    expect(cubits, hasLength(1));

    await tester.pumpWidget(app('company-b'));
    await tester.pump();
    expect(cubits.first.isClosed, isTrue);
    expect(repository.cancelled, contains('company-a'));
    expect(repository.watched, ['company-a', 'company-b']);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    expect(cubits.last.isClosed, isTrue);
    expect(repository.cancelled, contains('company-b'));
  });

  testWidgets('leaving Customers closes its realtime subscription', (
    tester,
  ) async {
    final repository = _TrackingRepository();
    final cubit = CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomersRealtimeBoundary(
          currentCompanyContext: _context('company-a'),
          realtimeCubitFactory: () => cubit,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    expect(repository.watched, ['company-a']);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(repository.cancelled, ['company-a']);
    expect(cubit.isClosed, isTrue);
  });
}

CurrentCompanyContext _context(String companyId) => CurrentCompanyContext(
  company: Company(id: companyId, name: 'Fixture company'),
  role: CompanyRole.owner,
);

final class _TrackingRepository implements CompanyDataChangesRepository {
  final List<String> watched = [];
  final List<String> cancelled = [];

  @override
  Stream<Result<CompanyDataChange>> watchChanges({required String companyId}) {
    final controller = StreamController<Result<CompanyDataChange>>(
      onListen: () => watched.add(companyId),
      onCancel: () => cancelled.add(companyId),
    );
    return controller.stream;
  }
}
