import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/usecases/set_trip_freight_rate_usecase.dart';

sealed class TripFreightRateState {
  const TripFreightRateState();
}

final class TripFreightRateInitial extends TripFreightRateState {
  const TripFreightRateInitial();
}

final class TripFreightRateSaving extends TripFreightRateState {
  const TripFreightRateSaving();
}

final class TripFreightRateSaved extends TripFreightRateState {
  final TripEntity trip;

  const TripFreightRateSaved(this.trip);
}

final class TripFreightRateFailure extends TripFreightRateState {
  final Failure failure;

  const TripFreightRateFailure(this.failure);
}

final class TripFreightRateCubit extends Cubit<TripFreightRateState> {
  final SetTripFreightRateUseCase _setFreightRate;

  TripFreightRateCubit(this._setFreightRate)
    : super(const TripFreightRateInitial());

  void reset() {
    if (!isClosed) emit(const TripFreightRateInitial());
  }

  Future<void> save({
    required CurrentCompanyContext companyContext,
    required TripEntity trip,
    required String agreedFreightRatePerTonInput,
  }) async {
    if (isClosed || state is TripFreightRateSaving) return;
    emit(const TripFreightRateSaving());

    final result = await _setFreightRate(
      SetTripFreightRateParams(
        currentCompanyContext: companyContext,
        trip: trip,
        agreedFreightRatePerTonInput: agreedFreightRatePerTonInput,
      ),
    );
    if (isClosed) return;

    result.when(
      success: (updated) => emit(TripFreightRateSaved(updated)),
      failure: (failure) => emit(TripFreightRateFailure(failure)),
    );
  }
}
