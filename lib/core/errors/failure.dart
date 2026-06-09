abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() {
    if (code == null || code!.isEmpty) {
      return message;
    }

    return '$code: $message';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is Failure &&
            other.message == message &&
            other.code == code;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, code);
}
