import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../domain/entities/driver_compensation_revision.dart';

abstract final class DriverCompensationFormatters {
  static const MoneyDecimalCodec _moneyCodec = MoneyDecimalCodec();

  static String date(BusinessDate value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String amount(DriverCompensationRevision revision) {
    final configuration = CurrencyConfiguration(
      currency: revision.amount.currency,
      fractionDigits: revision.currencyFractionDigits,
    );
    final value = _moneyCodec.encodeNonNegative(
      revision.amount,
      configuration: configuration,
    );
    return '$value ${revision.amount.currency.value}';
  }
}
