import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
import 'package:horus_system/core/realtime/domain/repositories/company_data_changes_repository.dart';
import 'package:horus_system/core/realtime/domain/usecases/watch_company_data_changes_usecase.dart';
import 'package:horus_system/core/realtime/presentation/cubit/company_realtime_cubit.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/app_shell/presentation/widgets/company_realtime_session_boundary.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/customers/presentation/widgets/customers_realtime_boundary.dart';

void main() {
  testWidgets('leaving Customers keeps one company-session channel', (
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

    Widget app(bool customersVisible) => Directionality(
      textDirection: TextDirection.ltr,
      child: CompanyRealtimeSessionBoundary(
        companyId: 'company-a',
        role: CompanyRole.owner,
        userId: 'user-1',
        realtimeCubitFactory: factory,
        child: customersVisible
            ? CustomersRealtimeBoundary(
                currentCompanyContext: _context('company-a'),
                child: const SizedBox.shrink(),
              )
            : const SizedBox.shrink(),
      ),
    );

    await tester.pumpWidget(app(true));
    expect(repository.watched, ['company-a']);
    expect(cubits, hasLength(1));

    await tester.pumpWidget(app(false));
    await tester.pump();
    expect(repository.cancelled, isEmpty);
    expect(cubits.single.isClosed, isFalse);

    await tester.pumpWidget(app(true));
    expect(repository.watched, ['company-a']);
    expect(cubits, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(repository.cancelled, ['company-a']);
    expect(cubits.single.isClosed, isTrue);
  });

  testWidgets('changing company replaces and disposes the old channel', (
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

    Widget app(String companyId) => Directionality(
      textDirection: TextDirection.ltr,
      child: CompanyRealtimeSessionBoundary(
        companyId: companyId,
        role: CompanyRole.owner,
        userId: 'user-1',
        realtimeCubitFactory: factory,
        child: CustomersRealtimeBoundary(
          currentCompanyContext: _context(companyId),
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(app('company-a'));
    await tester.pumpWidget(app('company-b'));
    await tester.pump();

    expect(repository.watched, ['company-a', 'company-b']);
    expect(repository.cancelled, contains('company-a'));
    expect(cubits.first.isClosed, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(repository.cancelled, contains('company-b'));
    expect(cubits.last.isClosed, isTrue);
  });

  testWidgets('driver role cannot open the Customers Broadcast topic', (
    tester,
  ) async {
    final repository = _TrackingRepository();
    await tester.pumpWidget(
      CompanyRealtimeSessionBoundary(
        companyId: 'company-a',
        role: CompanyRole.driver,
        userId: 'user-1',
        realtimeCubitFactory: () => CompanyRealtimeCubit(
          watchChanges: WatchCompanyDataChangesUseCase(repository),
        ),
        child: const SizedBox.shrink(),
      ),
    );

    expect(repository.watched, isEmpty);
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
