import 'package:horus_system/core/realtime/data/mappers/company_change_message_decoder.dart';
import 'package:test/test.dart';

void main() {
  test('Drivers accepts only current-company Drivers hints', () {
    expect(
      CompanyChangeMessageDecoder.isForCompanyAndResource({
        'payload': {'company_id': 'company-a', 'resource': 'drivers'},
      }, companyId: 'company-a', resource: 'drivers'),
      isTrue,
    );
    expect(
      CompanyChangeMessageDecoder.isForCompanyAndResource({
        'payload': {'company_id': 'company-b', 'resource': 'drivers'},
      }, companyId: 'company-a', resource: 'drivers'),
      isFalse,
    );
    expect(
      CompanyChangeMessageDecoder.isForCompanyAndResource({
        'payload': {'company_id': 'company-a', 'resource': 'customers'},
      }, companyId: 'company-a', resource: 'drivers'),
      isFalse,
    );
    expect(
      CompanyChangeMessageDecoder.isForCompanyAndResource(
        {'payload': 'invalid'}, companyId: 'company-a', resource: 'drivers',
      ),
      isFalse,
    );
  });
}
