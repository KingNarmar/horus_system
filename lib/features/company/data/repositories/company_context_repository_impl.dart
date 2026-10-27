import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/context/current_company_provider.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../../domain/repositories/company_context_repository.dart';
import '../datasources/company_context_remote_data_source.dart';
import '../mappers/company_membership_mapper.dart';
import 'company_context_repository_failure_mapper.dart';

class CompanyContextRepositoryImpl implements CompanyContextRepository {
  final CompanyContextRemoteDataSource _remoteDataSource;
  final CurrentCompanyProvider _currentCompanyProvider;

  List<CurrentCompanyContext> _loadedContexts = const [];
  int _contextEpoch = 0;
  int _loadGeneration = 0;

  CompanyContextRepositoryImpl({
    required CompanyContextRemoteDataSource remoteDataSource,
    required CurrentCompanyProvider currentCompanyProvider,
  }) : _remoteDataSource = remoteDataSource,
       _currentCompanyProvider = currentCompanyProvider;

  static const _failureMapper = CompanyContextRepositoryFailureMapper();

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    try {
      final epoch = _contextEpoch;
      final request = ++_loadGeneration;
      final memberships = await _remoteDataSource.loadUserCompanyMemberships();
      if (epoch != _contextEpoch || request != _loadGeneration) {
        return const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
        );
      }

      _loadedContexts = memberships
          .map((membership) => membership.toCurrentCompanyContext())
          .toList();

      return Success(_loadedContexts);
    } on AuthException catch (error) {
      return FailureResult(_failureMapper.fromAuthException(error));
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    try {
      final epoch = _contextEpoch;
      if (_loadedContexts.isEmpty) {
        final loadResult = await loadUserCompanyContexts();
        final failure = loadResult.failureOrNull;

        if (failure != null) {
          return FailureResult(failure);
        }
      }
      if (epoch != _contextEpoch) {
        return const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
        );
      }

      for (final context in _loadedContexts) {
        if (context.companyId == companyId) {
          _currentCompanyProvider.setCurrentCompanyId(context.companyId);
          return Success(context);
        }
      }

      return const FailureResult(
        ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
      );
    } on MissingCompanyContextException catch (error) {
      return FailureResult(_failureMapper.fromMissingCompanyContext(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async {
    try {
      final companyId = _currentCompanyProvider.currentCompanyId;

      if (companyId == null || companyId.trim().isEmpty) {
        return const Success(null);
      }

      if (_loadedContexts.isEmpty) {
        final loadResult = await loadUserCompanyContexts();
        final failure = loadResult.failureOrNull;

        if (failure != null) {
          return FailureResult(failure);
        }
      }

      for (final context in _loadedContexts) {
        if (context.companyId == companyId) {
          return Success(context);
        }
      }

      _currentCompanyProvider.clear();
      return const Success(null);
    } on MissingCompanyContextException catch (error) {
      return FailureResult(_failureMapper.fromMissingCompanyContext(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<void>> clearCurrentCompanyContext() async {
    ++_contextEpoch;
    ++_loadGeneration;
    try {
      _currentCompanyProvider.clear();
      _loadedContexts = const [];
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
