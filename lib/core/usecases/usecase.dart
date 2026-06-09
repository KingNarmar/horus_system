import '../utils/result.dart';

abstract class UseCase<Output, Params> {
  Future<Result<Output>> call(Params params);
}

abstract class StreamUseCase<Output, Params> {
  Stream<Result<Output>> call(Params params);
}

class NoParams {
  const NoParams();
}
