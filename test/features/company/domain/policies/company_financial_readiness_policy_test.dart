import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_financial_readiness.dart';
import 'package:horus_system/features/company/domain/policies/company_financial_readiness_policy.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyFinancialReadinessPolicy', () {
    test('requires configuration when currency pair is completely absent', () {
      final readiness = CompanyFinancialReadinessPolicy.evaluate(
        const Company(id: 'company-1', name: 'Horus Transport'),
      );

      expect(
        readiness.status,
        CompanyFinancialReadinessStatus.configurationRequired,
      );
      expect(readiness.configuration, isNull);
      expect(readiness.isReady, isFalse);
    });

    test('rejects partial or invalid financial configuration', () {
      final partial = CompanyFinancialReadinessPolicy.evaluate(
        const Company(
          id: 'company-1',
          name: 'Horus Transport',
          baseCurrencyCode: 'AED',
        ),
      );
      final invalid = CompanyFinancialReadinessPolicy.evaluate(
        const Company(
          id: 'company-1',
          name: 'Horus Transport',
          baseCurrencyCode: 'DIRHAM',
          baseCurrencyFractionDigits: 2,
        ),
      );

      expect(partial.status, CompanyFinancialReadinessStatus.invalidConfiguration);
      expect(invalid.status, CompanyFinancialReadinessStatus.invalidConfiguration);
    });

    test('returns canonical currency and precision when ready', () {
      final readiness = CompanyFinancialReadinessPolicy.evaluate(
        const Company(
          id: 'company-1',
          name: 'Horus Transport',
          baseCurrencyCode: 'AED',
          baseCurrencyFractionDigits: 2,
        ),
      );

      expect(readiness.status, CompanyFinancialReadinessStatus.ready);
      expect(readiness.configuration?.baseCurrency.value, 'AED');
      expect(readiness.configuration?.fractionDigits, 2);
      expect(readiness.isReady, isTrue);
    });
  });
}
