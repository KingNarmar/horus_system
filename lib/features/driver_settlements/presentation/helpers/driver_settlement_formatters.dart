import 'package:intl/intl.dart';

import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';
import '../../../../core/utils/business_local_date_time_date_time_adapter.dart';

const _moneyCodec = MoneyDecimalCodec();

String formatDriverSettlementDate(BusinessDate date, String localeName) {
  return DateFormat.yMMMd(
    localeName,
  ).format(BusinessDateDateTimeAdapter.toDateTime(date));
}

String formatDriverSettlementDateTime(
  BusinessLocalDateTime date,
  String localeName,
) {
  return DateFormat.yMMMd(
    localeName,
  ).add_jm().format(BusinessLocalDateTimeDateTimeAdapter.toDateTime(date));
}

String formatDriverSettlementAmount(double amount, String localeName) {
  return NumberFormat('#,##0.00', localeName).format(amount);
}

String formatDriverSettlementMoney(
  Money amount, {
  required int currencyFractionDigits,
}) {
  final configuration = CurrencyConfiguration(
    currency: amount.currency,
    fractionDigits: currencyFractionDigits,
  );
  final value = _moneyCodec.encode(amount, configuration: configuration);
  return '$value ${amount.currency.value}';
}
