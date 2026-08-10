import 'payment_method.dart';

enum PaymentMethodStatusFilter { active, inactive, all }

extension PaymentMethodStatusFilterX on PaymentMethodStatusFilter {
  bool matches(PaymentMethod method) {
    return switch (this) {
      PaymentMethodStatusFilter.active => method.isActive,
      PaymentMethodStatusFilter.inactive => !method.isActive,
      PaymentMethodStatusFilter.all => true,
    };
  }
}
