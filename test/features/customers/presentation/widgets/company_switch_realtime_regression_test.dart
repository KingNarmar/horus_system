import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/realtime/data/constants/realtime_topics.dart';
import 'package:horus_system/core/realtime/data/datasources/company_data_changes_remote_data_source.dart';
import 'package:horus_system/core/realtime/data/datasources/realtime_channel_gateway.dart';
import 'package:horus_system/core/realtime/data/repositories/company_data_changes_repository_impl.dart';
import 'package:horus_system/core/realtime/domain/entities/company_invalidation_resource.dart';
import 'package:horus_system/core/realtime/domain/usecases/watch_company_data_changes_usecase.dart';
import 'package:horus_system/core/realtime/presentation/cubit/company_realtime_cubit.dart';
import 'package:horus_system/core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import 'package:horus_system/features/app_shell/presentation/widgets/company_realtime_session_boundary.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';

void main() {
  testWidgets(
    'A -> B -> A with different roles receives new A events during old teardown',
    (tester) async {
      final gateway = _DeferredRemovalGateway();
      final dataSource =
          SupabaseCompanyDataChangesRemoteDataSource.withGateway(gateway);
      final watchChanges = WatchCompanyDataChangesUseCase(
        CompanyDataChangesRepositoryImpl(dataSource),
      );
      final invalidatedCompanies = <String>[];

      Widget companySession(String companyId, CompanyRole role) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: CompanyRealtimeSessionBoundary(
            companyId: companyId,
            role: role,
            userId: 'fixture-user',
            realtimeCubitFactory: () =>
                CompanyRealtimeCubit(watchChanges: watchChanges),
            child: CompanyResourceInvalidationBoundary(
              companyId: companyId,
              resources: const {CompanyInvalidationResource.customers},
              onInvalidate: (_) async {
                invalidatedCompanies.add(companyId);
              },
              child: const SizedBox.shrink(),
            ),
          ),
        );
      }

      const aTopic = 'horus:company:company-a:customers';
      const bTopic = 'horus:company:company-b:customers';

      await tester.pumpWidget(companySession('company-a', CompanyRole.admin));
      await tester.pump();
      final oldA = gateway.channelsFor(aTopic).single;
      oldA.subscribed();
      await tester.pump();
      invalidatedCompanies.clear();

      final removalBarrier = Completer<void>();
      gateway.delayRemovalOf = oldA;
      gateway.removalBarrier = removalBarrier;

      await tester.pumpWidget(companySession('company-b', CompanyRole.owner));
      await tester.pump();
      final b = gateway.channelsFor(bTopic).single;
      b.subscribed();
      await tester.pump();
      invalidatedCompanies.clear();

      await tester.pumpWidget(companySession('company-a', CompanyRole.admin));
      await tester.pump();
      final restoredA = gateway.channelsFor(aTopic).last;
      expect(identical(restoredA, oldA), isFalse);

      // The old company A and B callbacks may arrive after navigation.
      oldA.changed('company-a');
      b.changed('company-b');
      await tester.pump();
      expect(invalidatedCompanies, isEmpty);

      // Rejoining must reconcile missed events and accept fresh A messages.
      restoredA.subscribed();
      await tester.pump();
      expect(invalidatedCompanies, ['company-a']);
      invalidatedCompanies.clear();

      restoredA.changed('company-a');
      restoredA.changed('company-b');
      await tester.pump();
      expect(invalidatedCompanies, ['company-a']);

      removalBarrier.complete();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}

final class _DeferredRemovalGateway implements RealtimeChannelGateway {
  @override
  String? get accessToken => 'fixture-token';

  final List<_TestChannel> channels = [];
  _TestChannel? delayRemovalOf;
  Completer<void>? removalBarrier;

  List<_TestChannel> channelsFor(String topic) =>
      channels.where((channel) => channel.topic == topic).toList();

  @override
  Future<void> authenticate(String token) async {}

  @override
  RealtimeChannelHandle subscribe({
    required String topic,
    required String event,
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(RealtimeChannelJoinStatus) onStatus,
  }) {
    final channel = _TestChannel(
      topic: topic,
      onMessage: onMessage,
      onStatus: onStatus,
    );
    channels.add(channel);
    return channel;
  }

  @override
  Future<void> remove(RealtimeChannelHandle handle) async {
    if (identical(handle, delayRemovalOf)) {
      await removalBarrier!.future;
    }
  }
}

final class _TestChannel implements RealtimeChannelHandle {
  final String topic;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function(RealtimeChannelJoinStatus) onStatus;

  const _TestChannel({
    required this.topic,
    required this.onMessage,
    required this.onStatus,
  });

  void subscribed() => onStatus(RealtimeChannelJoinStatus.subscribed);

  void changed(String companyId) {
    onMessage({
      'payload': {
        'company_id': companyId,
        'resource': RealtimeTopics.customersResource,
      },
    });
  }
}
