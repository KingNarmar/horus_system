import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/network/data/datasources/network_status_data_source.dart';
import 'package:horus_system/core/network/data/repositories/network_status_repository_impl.dart';
import 'package:horus_system/core/network/domain/entities/network_connection_status.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkStatusRepositoryImpl', () {
    test('returns current connectivity status', () async {
      final repository = NetworkStatusRepositoryImpl(
        _FakeNetworkStatusDataSource(),
      );

      final result = await repository.getCurrentStatus();

      expect(result.dataOrNull, NetworkConnectionStatus.online);
    });

    test('maps datasource exceptions to typed network failure', () async {
      final repository = NetworkStatusRepositoryImpl(
        _FakeNetworkStatusDataSource(throwOnRead: true),
      );

      final result = await repository.getCurrentStatus();

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull?.code, FailureCodes.networkStatusUnavailable);
    });

    test('maps watch exceptions to typed network failure', () async {
      final repository = NetworkStatusRepositoryImpl(
        _FakeNetworkStatusDataSource(throwOnWatch: true),
      );

      final values = await repository.watchStatus().toList();

      expect(values, hasLength(1));
      expect(values.single.failureOrNull, isA<NetworkFailure>());
      expect(
        values.single.failureOrNull?.code,
        FailureCodes.networkStatusUnavailable,
      );
    });
  });
}

final class _FakeNetworkStatusDataSource implements NetworkStatusDataSource {
  final bool throwOnRead;
  final bool throwOnWatch;

  const _FakeNetworkStatusDataSource({
    this.throwOnRead = false,
    this.throwOnWatch = false,
  });

  @override
  Future<NetworkConnectionStatus> getCurrentStatus() async {
    if (throwOnRead) throw StateError('external failure');
    return NetworkConnectionStatus.online;
  }

  @override
  Stream<NetworkConnectionStatus> watchStatus() async* {
    if (throwOnWatch) throw StateError('external failure');
    yield NetworkConnectionStatus.offline;
  }
}
