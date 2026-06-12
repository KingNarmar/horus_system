abstract class Failure {
  final String code;
  final String? message;

  const Failure({required this.code, this.message});

  @override
  String toString() {
    if (message == null || message!.isEmpty) {
      return code;
    }

    return '$code: $message';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is Failure &&
            other.code == code;
  }

  @override
  int get hashCode => Object.hash(runtimeType, code);
}
