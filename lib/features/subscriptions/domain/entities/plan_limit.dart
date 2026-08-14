final class PlanLimit {
  final int? value;

  const PlanLimit(this.value);

  const PlanLimit.unlimited() : value = null;

  bool get isUnlimited => value == null;
}
