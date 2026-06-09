import '../errors/failure.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is FailureResult<T>;

  T? get dataOrNull {
    final current = this;

    if (current is Success<T>) {
      return current.data;
    }

    return null;
  }

  Failure? get failureOrNull {
    final current = this;

    if (current is FailureResult<T>) {
      return current.failure;
    }

    return null;
  }

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final current = this;

    if (current is Success<T>) {
      return success(current.data);
    }

    if (current is FailureResult<T>) {
      return failure(current.failure);
    }

    throw StateError('Unhandled Result type: $runtimeType');
  }
}

class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);
}

class FailureResult<T> extends Result<T> {
  final Failure failure;

  const FailureResult(this.failure);
}
