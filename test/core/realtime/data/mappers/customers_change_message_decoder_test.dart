import 'package:horus_system/core/realtime/data/mappers/customers_change_message_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('CustomersChangeMessageDecoder', () {
    test('accepts a server envelope for the active company', () {
      expect(
        CustomersChangeMessageDecoder.isForCompany({
          'event': 'changed',
          'type': 'broadcast',
          'payload': {
            'company_id': 'company-a',
            'resource': 'customers',
            'id': 'server-signal-id',
          },
        }, companyId: 'company-a'),
        isTrue,
      );
    });

    test('rejects a message targeting a different company', () {
      expect(
        CustomersChangeMessageDecoder.isForCompany({
          'payload': {'company_id': 'company-b', 'resource': 'customers'},
        }, companyId: 'company-a'),
        isFalse,
      );
    });

    test('rejects unrelated resources and malformed payloads', () {
      for (final envelope in [
        <String, dynamic>{},
        <String, dynamic>{'payload': null},
        <String, dynamic>{'payload': 'invalid'},
        <String, dynamic>{
          'payload': {'company_id': 'company-a', 'resource': 'payments'},
        },
        <String, dynamic>{
          'payload': {'company_id': 'company-a'},
        },
      ]) {
        expect(
          CustomersChangeMessageDecoder.isForCompany(
            envelope,
            companyId: 'company-a',
          ),
          isFalse,
        );
      }
    });
  });
}
