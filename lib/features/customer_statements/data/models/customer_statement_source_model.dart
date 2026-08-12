import '../constants/customer_statements_db_constants.dart';

final class CustomerStatementSourceModel {
  final String companyId;
  final String baseCurrencyCode;
  final int baseCurrencyFractionDigits;
  final String businessTimezone;
  final String customerId;
  final String customerName;
  final bool customerIsActive;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<CustomerStatementOpeningAmountModel> openingInvoices;
  final List<CustomerStatementOpeningAmountModel> openingPayments;
  final List<CustomerStatementMovementModel> movements;

  const CustomerStatementSourceModel({
    required this.companyId,
    required this.baseCurrencyCode,
    required this.baseCurrencyFractionDigits,
    required this.businessTimezone,
    required this.customerId,
    required this.customerName,
    required this.customerIsActive,
    required this.fromDate,
    required this.toDate,
    required this.openingInvoices,
    required this.openingPayments,
    required this.movements,
  });

  factory CustomerStatementSourceModel.fromMap(Map<String, dynamic> map) {
    final company = _requiredMap(
      map[CustomerStatementsDbConstants.company],
      CustomerStatementsDbConstants.company,
    );
    final customer = _requiredMap(
      map[CustomerStatementsDbConstants.customer],
      CustomerStatementsDbConstants.customer,
    );
    final period = _requiredMap(
      map[CustomerStatementsDbConstants.period],
      CustomerStatementsDbConstants.period,
    );
    final opening = _requiredMap(
      map[CustomerStatementsDbConstants.opening],
      CustomerStatementsDbConstants.opening,
    );

    return CustomerStatementSourceModel(
      companyId: _requiredString(
        company[CustomerStatementsDbConstants.companyId],
        CustomerStatementsDbConstants.companyId,
      ),
      baseCurrencyCode: _requiredString(
        company[CustomerStatementsDbConstants.baseCurrencyCode],
        CustomerStatementsDbConstants.baseCurrencyCode,
      ),
      baseCurrencyFractionDigits: _requiredInt(
        company[CustomerStatementsDbConstants.baseCurrencyFractionDigits],
        CustomerStatementsDbConstants.baseCurrencyFractionDigits,
      ),
      businessTimezone: _requiredString(
        company[CustomerStatementsDbConstants.businessTimezone],
        CustomerStatementsDbConstants.businessTimezone,
      ),
      customerId: _requiredString(
        customer[CustomerStatementsDbConstants.customerId],
        CustomerStatementsDbConstants.customerId,
      ),
      customerName: _requiredString(
        customer[CustomerStatementsDbConstants.customerName],
        CustomerStatementsDbConstants.customerName,
      ),
      customerIsActive: _requiredBool(
        customer[CustomerStatementsDbConstants.isActive],
        CustomerStatementsDbConstants.isActive,
      ),
      fromDate: _optionalDate(
        period[CustomerStatementsDbConstants.fromDate],
        CustomerStatementsDbConstants.fromDate,
      ),
      toDate: _optionalDate(
        period[CustomerStatementsDbConstants.toDate],
        CustomerStatementsDbConstants.toDate,
      ),
      openingInvoices:
          _requiredList(
                opening[CustomerStatementsDbConstants.invoices],
                CustomerStatementsDbConstants.invoices,
              )
              .map(CustomerStatementOpeningAmountModel.fromMap)
              .toList(growable: false),
      openingPayments:
          _requiredList(
                opening[CustomerStatementsDbConstants.payments],
                CustomerStatementsDbConstants.payments,
              )
              .map(CustomerStatementOpeningAmountModel.fromMap)
              .toList(growable: false),
      movements: _requiredList(
        map[CustomerStatementsDbConstants.movements],
        CustomerStatementsDbConstants.movements,
      ).map(CustomerStatementMovementModel.fromMap).toList(growable: false),
    );
  }
}

final class CustomerStatementOpeningAmountModel {
  final String currencyCode;
  final int totalMinorUnits;

  const CustomerStatementOpeningAmountModel({
    required this.currencyCode,
    required this.totalMinorUnits,
  });

  factory CustomerStatementOpeningAmountModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return CustomerStatementOpeningAmountModel(
      currencyCode: _requiredString(
        map[CustomerStatementsDbConstants.currencyCode],
        CustomerStatementsDbConstants.currencyCode,
      ),
      totalMinorUnits: _requiredInt(
        map[CustomerStatementsDbConstants.totalMinorUnits],
        CustomerStatementsDbConstants.totalMinorUnits,
      ),
    );
  }
}

final class CustomerStatementMovementModel {
  final String sourceType;
  final String sourceId;
  final DateTime businessDate;
  final DateTime eventTimestamp;
  final int amountMinorUnits;
  final String currencyCode;
  final String? reference;
  final String relatedInvoiceId;

  const CustomerStatementMovementModel({
    required this.sourceType,
    required this.sourceId,
    required this.businessDate,
    required this.eventTimestamp,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.reference,
    required this.relatedInvoiceId,
  });

  factory CustomerStatementMovementModel.fromMap(Map<String, dynamic> map) {
    return CustomerStatementMovementModel(
      sourceType: _requiredString(
        map[CustomerStatementsDbConstants.sourceType],
        CustomerStatementsDbConstants.sourceType,
      ),
      sourceId: _requiredString(
        map[CustomerStatementsDbConstants.sourceId],
        CustomerStatementsDbConstants.sourceId,
      ),
      businessDate: _requiredDate(
        map[CustomerStatementsDbConstants.businessDate],
        CustomerStatementsDbConstants.businessDate,
      ),
      eventTimestamp: _requiredDateTime(
        map[CustomerStatementsDbConstants.eventTimestamp],
        CustomerStatementsDbConstants.eventTimestamp,
      ),
      amountMinorUnits: _requiredInt(
        map[CustomerStatementsDbConstants.amountMinorUnits],
        CustomerStatementsDbConstants.amountMinorUnits,
      ),
      currencyCode: _requiredString(
        map[CustomerStatementsDbConstants.currencyCode],
        CustomerStatementsDbConstants.currencyCode,
      ),
      reference: _optionalString(
        map[CustomerStatementsDbConstants.reference],
        CustomerStatementsDbConstants.reference,
      ),
      relatedInvoiceId: _requiredString(
        map[CustomerStatementsDbConstants.relatedInvoiceId],
        CustomerStatementsDbConstants.relatedInvoiceId,
      ),
    );
  }
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('Invalid customer statement object: $field.');
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _requiredList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('Invalid customer statement list: $field.');
  }

  return value
      .map((item) {
        if (item is! Map) {
          throw FormatException(
            'Invalid customer statement list item: $field.',
          );
        }
        return Map<String, dynamic>.from(item);
      })
      .toList(growable: false);
}

String _requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid customer statement field: $field.');
  }
  return value.trim();
}

String? _optionalString(Object? value, String field) {
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Invalid customer statement field: $field.');
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

int _requiredInt(Object? value, String field) {
  if (value is int) return value;
  if (value is num && value == value.truncate()) return value.toInt();
  throw FormatException('Invalid customer statement integer field: $field.');
}

bool _requiredBool(Object? value, String field) {
  if (value is bool) return value;
  throw FormatException('Invalid customer statement boolean field: $field.');
}

DateTime _requiredDate(Object? value, String field) {
  final raw = _requiredString(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('Invalid customer statement date: $field.');
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _optionalDate(Object? value, String field) {
  if (value == null) return null;
  return _requiredDate(value, field);
}

DateTime _requiredDateTime(Object? value, String field) {
  final raw = _requiredString(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('Invalid customer statement timestamp: $field.');
  }
  return parsed;
}
