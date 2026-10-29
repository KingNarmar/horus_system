import '../../../../core/errors/failure.dart';
import '../../domain/entities/current_company_context.dart';

sealed class CurrentCompanyState {
  const CurrentCompanyState();
}

class CurrentCompanyInitial extends CurrentCompanyState {
  const CurrentCompanyInitial();
}

class CurrentCompanyLoading extends CurrentCompanyState {
  const CurrentCompanyLoading();
}

/// Blocks interaction during an authoritative membership check while keeping
/// the existing company shell mounted so unsaved form state can survive.
class CurrentCompanyVerifying extends CurrentCompanyState {
  final CurrentCompanyContext context;

  /// A failed connection check must hide the previously verified company UI
  /// without destroying its local navigation and unsaved form state.
  final Failure? connectionFailure;

  const CurrentCompanyVerifying(this.context, {this.connectionFailure});
}

class CurrentCompanyEmpty extends CurrentCompanyState {
  const CurrentCompanyEmpty();
}

class CurrentCompanyLoaded extends CurrentCompanyState {
  final CurrentCompanyContext context;

  const CurrentCompanyLoaded(this.context);
}

class CurrentCompanyFailure extends CurrentCompanyState {
  final Failure failure;

  /// Identifies the company to check after reconnect. No cached role or
  /// authorization data is retained while verification has failed.
  final String? selectedCompanyId;

  const CurrentCompanyFailure(this.failure, {this.selectedCompanyId});
}
