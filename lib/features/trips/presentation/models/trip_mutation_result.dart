import '../../../../core/errors/failure.dart';

sealed class TripMutationResult {
  const TripMutationResult();
}

final class TripMutationSucceeded extends TripMutationResult {
  const TripMutationSucceeded();
}

final class TripMutationFailed extends TripMutationResult {
  final Failure failure;

  const TripMutationFailed(this.failure);
}

final class TripMutationIgnored extends TripMutationResult {
  const TripMutationIgnored();
}
