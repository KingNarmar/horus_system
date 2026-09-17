import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../company/data/constants/company_db_fields.dart';
import '../constants/driver_finance_db_fields.dart';
import '../mappers/driver_balance_mapper.dart';
import '../models/driver_balance_model.dart';
import '../utils/driver_balance_source_selector.dart';

const _driverFinancialMovementColumns = '''
id,
company_id,
driver_id,
trip_id,
movement_type,
amount_minor_units,
currency_code,
currency_fraction_digits,
movement_date,
notes,
created_at,
updated_at
''';

const _expenseLedgerColumns = '''
id,
company_id,
driver_id,
trip_id,
amount_minor_units,
currency_code,
currency_fraction_digits,
funding_source,
expense_date,
created_at
''';

abstract class CanonicalDriverBalanceRemoteDataSource {
  Future<DriverBalanceModel> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  });
}

class SupabaseCanonicalDriverBalanceRemoteDataSource
    implements CanonicalDriverBalanceRemoteDataSource {
  final SupabaseClient client;
  final DriverBalanceSourceMapper balanceSourceMapper;
  final DriverBalanceSourceSelector sourceSelector;

  const SupabaseCanonicalDriverBalanceRemoteDataSource(
    this.client, {
    this.balanceSourceMapper = const DriverBalanceSourceMapper(),
    this.sourceSelector = const DriverBalanceSourceSelector(),
  });

  @override
  Future<DriverBalanceModel> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    final configuration = await _getCurrencyConfiguration(companyId);
    final checkpointRow = await _getBalanceCheckpoint(
      companyId: companyId,
      driverId: driverId,
      checkpointBeforeExclusive: checkpointBeforeExclusive,
    );
    final movementRows = await _getMovementRows(
      companyId: companyId,
      driverId: driverId,
      beforeExclusive: beforeExclusive,
      checkpointRow: checkpointRow,
    );
    final expenseRows = await _getDriverExpenseRows(
      companyId: companyId,
      driverId: driverId,
      beforeExclusive: beforeExclusive,
      checkpointRow: checkpointRow,
    );

    return balanceSourceMapper.map(
      companyId: companyId,
      driverId: driverId,
      configuration: configuration,
      checkpointRow: checkpointRow,
      movementRows: movementRows,
      tripExpenseRows: expenseRows,
    );
  }

  Future<CurrencyConfiguration> _getCurrencyConfiguration(
    String companyId,
  ) async {
    final row = await client
        .from(CompanyDbFields.companiesTable)
        .select(
          '${CompanyDbFields.baseCurrencyCode},'
          '${CompanyDbFields.baseCurrencyFractionDigits}',
        )
        .eq(DbCommonFields.id, companyId)
        .single();
    final configuration = CurrencyConfiguration.tryCreate(
      currencyCode: row[CompanyDbFields.baseCurrencyCode] as String?,
      fractionDigits:
          row[CompanyDbFields.baseCurrencyFractionDigits] as int?,
    );
    if (configuration == null) {
      throw const FormatException('Company financial configuration is invalid.');
    }
    return configuration;
  }

  Future<Map<String, dynamic>?> _getBalanceCheckpoint({
    required String companyId,
    required String driverId,
    required BusinessDate? checkpointBeforeExclusive,
  }) async {
    final response = await client.rpc(
      DriverFinanceDbFunctions.getBalanceCheckpoint,
      params: {
        DriverFinanceDbFields.parameterCompanyId: companyId,
        DriverFinanceDbFields.parameterDriverId: driverId,
        DriverFinanceDbFields.parameterBeforeExclusive:
            checkpointBeforeExclusive == null
            ? null
            : DbDate.encode(checkpointBeforeExclusive),
      },
    );

    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map && response.isNotEmpty) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getMovementRows({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    required Map<String, dynamic>? checkpointRow,
  }) async {
    final before = DbDate.encode(beforeExclusive);
    if (checkpointRow == null) {
      final rows = await client
          .from(DriverFinanceDbTables.driverFinancialMovements)
          .select(_driverFinancialMovementColumns)
          .eq(DbCommonFields.companyId, companyId)
          .eq(DriverFinanceDbFields.driverId, driverId)
          .lt(DriverFinanceDbFields.movementDate, before)
          .order(DriverFinanceDbFields.movementDate)
          .order(DbCommonFields.createdAt)
          .order(DbCommonFields.id);
      return sourceSelector.select(
        rows: _maps(rows),
        effectiveDateField: DriverFinanceDbFields.movementDate,
        beforeExclusive: beforeExclusive,
      );
    }

    final checkpointPeriodEnd = DbDate.decode(
      checkpointRow[DriverFinanceDbFields.checkpointPeriodEnd],
      field: DriverFinanceDbFields.checkpointPeriodEnd,
    );
    final snapshotCreatedAt = DbTimestamp.decode(
      checkpointRow[DriverFinanceDbFields.checkpointSnapshotCreatedAt],
      field: DriverFinanceDbFields.checkpointSnapshotCreatedAt,
    );

    final effectiveRows = await client
        .from(DriverFinanceDbTables.driverFinancialMovements)
        .select(_driverFinancialMovementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.driverId, driverId)
        .gt(
          DriverFinanceDbFields.movementDate,
          DbDate.encode(checkpointPeriodEnd),
        )
        .lt(DriverFinanceDbFields.movementDate, before)
        .order(DriverFinanceDbFields.movementDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

    final lateRows = await client
        .from(DriverFinanceDbTables.driverFinancialMovements)
        .select(_driverFinancialMovementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.driverId, driverId)
        .gt(DbCommonFields.createdAt, DbTimestamp.encode(snapshotCreatedAt))
        .lt(DriverFinanceDbFields.movementDate, before)
        .order(DriverFinanceDbFields.movementDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

    return sourceSelector.select(
      rows: [..._maps(effectiveRows), ..._maps(lateRows)],
      effectiveDateField: DriverFinanceDbFields.movementDate,
      beforeExclusive: beforeExclusive,
      checkpointPeriodEnd: checkpointPeriodEnd,
      checkpointSnapshotCreatedAt: snapshotCreatedAt,
    );
  }

  Future<List<Map<String, dynamic>>> _getDriverExpenseRows({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    required Map<String, dynamic>? checkpointRow,
  }) async {
    final before = DbDate.encode(beforeExclusive);
    if (checkpointRow == null) {
      final rows = await client
          .from(DriverFinanceDbTables.expenseLedgerEntries)
          .select(_expenseLedgerColumns)
          .eq(DbCommonFields.companyId, companyId)
          .eq(DriverFinanceDbFields.driverId, driverId)
          .eq(DriverFinanceDbFields.isVoided, false)
          .inFilter(DriverFinanceDbFields.fundingSource, const [
            DriverFinanceDbValues.fundingSourceDriverAdvance,
            DriverFinanceDbValues.fundingSourceDriverCash,
          ])
          .lt(DriverFinanceDbFields.expenseDate, before)
          .order(DriverFinanceDbFields.expenseDate)
          .order(DbCommonFields.createdAt)
          .order(DbCommonFields.id);
      return sourceSelector.select(
        rows: _maps(rows),
        effectiveDateField: DriverFinanceDbFields.expenseDate,
        beforeExclusive: beforeExclusive,
      );
    }

    final checkpointPeriodEnd = DbDate.decode(
      checkpointRow[DriverFinanceDbFields.checkpointPeriodEnd],
      field: DriverFinanceDbFields.checkpointPeriodEnd,
    );
    final snapshotCreatedAt = DbTimestamp.decode(
      checkpointRow[DriverFinanceDbFields.checkpointSnapshotCreatedAt],
      field: DriverFinanceDbFields.checkpointSnapshotCreatedAt,
    );

    final effectiveRows = await client
        .from(DriverFinanceDbTables.expenseLedgerEntries)
        .select(_expenseLedgerColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.driverId, driverId)
        .eq(DriverFinanceDbFields.isVoided, false)
        .inFilter(DriverFinanceDbFields.fundingSource, const [
          DriverFinanceDbValues.fundingSourceDriverAdvance,
          DriverFinanceDbValues.fundingSourceDriverCash,
        ])
        .gt(
          DriverFinanceDbFields.expenseDate,
          DbDate.encode(checkpointPeriodEnd),
        )
        .lt(DriverFinanceDbFields.expenseDate, before)
        .order(DriverFinanceDbFields.expenseDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

    final lateRows = await client
        .from(DriverFinanceDbTables.expenseLedgerEntries)
        .select(_expenseLedgerColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.driverId, driverId)
        .eq(DriverFinanceDbFields.isVoided, false)
        .inFilter(DriverFinanceDbFields.fundingSource, const [
          DriverFinanceDbValues.fundingSourceDriverAdvance,
          DriverFinanceDbValues.fundingSourceDriverCash,
        ])
        .gt(DbCommonFields.createdAt, DbTimestamp.encode(snapshotCreatedAt))
        .lt(DriverFinanceDbFields.expenseDate, before)
        .order(DriverFinanceDbFields.expenseDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

    return sourceSelector.select(
      rows: [..._maps(effectiveRows), ..._maps(lateRows)],
      effectiveDateField: DriverFinanceDbFields.expenseDate,
      beforeExclusive: beforeExclusive,
      checkpointPeriodEnd: checkpointPeriodEnd,
      checkpointSnapshotCreatedAt: snapshotCreatedAt,
    );
  }

  List<Map<String, dynamic>> _maps(Iterable<dynamic> rows) {
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }
}
