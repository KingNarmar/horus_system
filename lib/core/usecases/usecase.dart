import '../utils/result.dart';

abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

abstract class StreamUseCase<Type, Params> {
  Stream<Result<Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
