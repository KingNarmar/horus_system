import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_status_filter.dart';
import 'package:test/test.dart';

void main() {
  test('status filter matches active, inactive, and all correctly', () {
    const active = PaymentMethod(
      id: 'active',
      companyId: 'company-1',
      name: 'Cash',
      isActive: true,
    );
    const inactive = PaymentMethod(
      id: 'inactive',
      companyId: 'company-1',
      name: 'Cheque',
      isActive: false,
    );

    expect(PaymentMethodStatusFilter.active.matches(active), isTrue);
    expect(PaymentMethodStatusFilter.active.matches(inactive), isFalse);
    expect(PaymentMethodStatusFilter.inactive.matches(active), isFalse);
    expect(PaymentMethodStatusFilter.inactive.matches(inactive), isTrue);
    expect(PaymentMethodStatusFilter.all.matches(active), isTrue);
    expect(PaymentMethodStatusFilter.all.matches(inactive), isTrue);
  });
}
