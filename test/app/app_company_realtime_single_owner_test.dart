import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app/app_company_realtime_scope.dart';
import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
import 'package:horus_system/core/realtime/domain/entities/company_invalidation_resource.dart';
import 'package:horus_system/core/realtime/domain/repositories/company_data_changes_repository.dart';
import 'package:horus_system/core/realtime/domain/usecases/watch_company_data_changes_usecase.dart';
import 'package:horus_system/core/realtime/presentation/cubit/company_realtime_cubit.dart';
import 'package:horus_system/core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';

void main() {
  testWidgets(
    'stacked shell routes share one session; A -> B -> A resets navigator',
    (tester) async {
      final repository = _WatchingRepository();
      addTearDown(repository.close);
      final changes = WatchCompanyDataChangesUseCase(repository);
      final invalidated = <String>[];

      Widget shell(String label, String companyId) =>
          CompanyResourceInvalidationBoundary(
            companyId: companyId,
            resources: const {CompanyInvalidationResource.customers},
            onInvalidate: (_) async {
              invalidated.add(companyId);
            },
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => shell('nested', companyId),
                    ),
                  ),
                  child: Text(label),
                ),
              ),
            ),
          );

      Widget app(String? companyId, CompanyRole role) =>
          AppCompanyRealtimeScope(
            companyContext: companyId == null
                ? null
                : CurrentCompanyContext(
                    company: Company(id: companyId, name: 'Fixture'),
                    role: role,
                  ),
            userId: 'fixture-user',
            realtimeCubitFactory: () {
              return CompanyRealtimeCubit(watchChanges: changes);
            },
            child: MaterialApp(
              home: companyId == null
                  ? const SizedBox.shrink()
                  : shell('root', companyId),
            ),
          );

      await tester.pumpWidget(app('company-a', CompanyRole.admin));
      await tester.pump();
      expect(repository.watched, ['company-a']);

      await tester.tap(find.text('root'));
      await tester.pumpAndSettle();
      expect(find.text('nested'), findsOneWidget);
      expect(repository.watched, ['company-a']);

      // A tenant switch must discard the entire Navigator history.
      await tester.pumpWidget(app('company-b', CompanyRole.owner));
      await tester.pump();
      expect(find.text('nested'), findsNothing);
      expect(repository.watched, ['company-a', 'company-b']);
      expect(repository.cancelled, contains('company-a'));

      await tester.pumpWidget(app('company-a', CompanyRole.admin));
      await tester.pump();
      expect(find.text('nested'), findsNothing);
      expect(repository.watched, ['company-a', 'company-b', 'company-a']);
      expect(repository.cancelled, contains('company-b'));

      // A fresh event for A refreshes A. The disposed B stream cannot
      // invalidate the new A view.
      invalidated.clear();
      repository.send('company-b');
      await tester.pump();
      expect(invalidated, isEmpty);

      repository.send('company-a');
      await tester.pump();
      expect(invalidated, ['company-a']);

      // An unchanged membership revalidation must not recreate the session.
      await tester.pumpWidget(app('company-a', CompanyRole.admin));
      await tester.pump();
      expect(repository.watched, ['company-a', 'company-b', 'company-a']);

      await tester.pumpWidget(app(null, CompanyRole.admin));
      await tester.pump();
      expect(repository.cancelled, contains('company-a'));
    },
  );
}

final class _WatchingRepository implements CompanyDataChangesRepository {
  final watched = <String>[];
  final cancelled = <String>[];
  final controllers = <StreamController<Result<CompanyDataChange>>>[];
  final latest = <String, StreamController<Result<CompanyDataChange>>>{};

  @override
  Stream<Result<CompanyDataChange>> watchChanges({
    required String companyId,
    Set<CompanyDataResource> additionalResources = const {},
  }) {
    final controller = StreamController<Result<CompanyDataChange>>(
      onListen: () => watched.add(companyId),
      onCancel: () => cancelled.add(companyId),
    );
    latest[companyId] = controller;
    controllers.add(controller);
    return controller.stream;
  }

  void send(String companyId) {
    latest[companyId]?.add(
      Success(
        CompanyDataChange(
          companyId: companyId,
          resource: CompanyDataResource.customers,
        ),
      ),
    );
  }

  Future<void> close() async {
    for (final controller in controllers) {
      await controller.close();
    }
  }
}
