import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/context/current_company_provider.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/repositories/company_context_repository.dart';
import '../datasources/company_context_remote_data_source.dart';
import '../mappers/company_membership_mapper.dart';

class CompanyContextRepositoryImpl implements CompanyContextRepository {
  final CompanyContextRemoteDataSource _remoteDataSource;
  final CurrentCompanyProvider _currentCompanyProvider;

  List<CurrentCompanyContext> _loadedContexts = const [];

  CompanyContextRepositoryImpl({
    required CompanyContextRemoteDataSource remoteDataSource,
    required CurrentCompanyProvider currentCompanyProvider,
  }) : _remoteDataSource = remoteDataSource,
       _currentCompanyProvider = currentCompanyProvider;

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    try {
      final memberships = await _remoteDataSource.loadUserCompanyMemberships();

      _loadedContexts = memberships
          .map((membership) => membership.toCurrentCompanyContext())
          .toList();

      return Success(_loadedContexts);
    } on AuthException catch (error) {
      return FailureResult(
        AuthFailure(
          code: error.statusCode ?? 'auth_error',
          message: error.message,
        ),
      );
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    try {
      if (_loadedContexts.isEmpty) {
        final loadResult = await loadUserCompanyContexts();
        final failure = loadResult.failureOrNull;

        if (failure != null) {
          return FailureResult(failure);
        }
      }

      final normalizedCompanyId = companyId.trim();

      for (final context in _loadedContexts) {
        if (context.companyId == normalizedCompanyId) {
          _currentCompanyProvider.setCurrentCompanyId(context.companyId);
          return Success(context);
        }
      }

      return const FailureResult(
        ValidationFailure(
          code: 'company_not_available',
          message: 'Selected company is not available for the current user.',
        ),
      );
    } on MissingCompanyContextException catch (error) {
      return FailureResult(
        ValidationFailure(code: 'validation_error', message: error.message),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async {
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
  }

  @override
  Future<Result<void>> clearCurrentCompanyContext() async {
    _currentCompanyProvider.clear();
    _loadedContexts = const [];
    return const Success<void>(null);
  }
}
