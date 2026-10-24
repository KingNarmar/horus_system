import '../../../../core/errors/failure.dart';
import '../../domain/entities/dashboard_summary.dart';

sealed class DashboardState {
  const DashboardState();
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  final Failure? realtimeRefreshFailure;

  const DashboardLoaded(this.summary, {this.realtimeRefreshFailure});
}

final class DashboardLoadFailure extends DashboardState {
  final Failure failure;

  const DashboardLoadFailure(this.failure);
}
