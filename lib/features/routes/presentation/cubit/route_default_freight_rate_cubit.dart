import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/usecases/set_route_default_freight_rate_usecase.dart';

sealed class RouteDefaultFreightRateState {
  const RouteDefaultFreightRateState();
}

final class RouteDefaultFreightRateInitial
    extends RouteDefaultFreightRateState {
  const RouteDefaultFreightRateInitial();
}

final class RouteDefaultFreightRateSaving extends RouteDefaultFreightRateState {
  const RouteDefaultFreightRateSaving();
}

final class RouteDefaultFreightRateSaved extends RouteDefaultFreightRateState {
  final RouteEntity route;

  const RouteDefaultFreightRateSaved(this.route);
}

final class RouteDefaultFreightRateFailure
    extends RouteDefaultFreightRateState {
  final Failure failure;

  const RouteDefaultFreightRateFailure(this.failure);
}

final class RouteDefaultFreightRateCubit
    extends Cubit<RouteDefaultFreightRateState> {
  final SetRouteDefaultFreightRateUseCase _useCase;

  RouteDefaultFreightRateCubit(this._useCase)
    : super(const RouteDefaultFreightRateInitial());

  void reset() {
    if (!isClosed) emit(const RouteDefaultFreightRateInitial());
  }

  Future<void> save({
    required CurrentCompanyContext currentCompanyContext,
    required RouteEntity route,
    required String rateInput,
  }) async {
    if (isClosed || state is RouteDefaultFreightRateSaving) return;
    emit(const RouteDefaultFreightRateSaving());

    final result = await _useCase(
      SetRouteDefaultFreightRateParams(
        currentCompanyContext: currentCompanyContext,
        route: route,
        rateInput: rateInput,
      ),
    );
    if (isClosed) return;
    result.when(
      success: (route) => emit(RouteDefaultFreightRateSaved(route)),
      failure: (failure) => emit(RouteDefaultFreightRateFailure(failure)),
    );
  }
}
