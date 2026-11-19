import 'package:test/test.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_kind.dart';

void main() {
  test('all six operational reports map to distinct dimensions', () {
    const expected = [
      OperationalReportDimension.day,
      OperationalReportDimension.customer,
      OperationalReportDimension.route,
      OperationalReportDimension.driver,
      OperationalReportDimension.tractorHead,
      OperationalReportDimension.trailer,
    ];
    expect(
      ReportExportKind.values.take(6).map((kind) => kind.operationalDimension),
      expected,
    );
    expect(
      ReportExportKind.values.skip(6).every(
        (kind) => kind.operationalDimension == null,
      ),
      isTrue,
    );
  });

  test('report export does not enlarge existing role permissions', () {
    for (final kind in ReportExportKind.values) {
      expect(kind.canView(CompanyRole.driver), isFalse);
      expect(kind.canView(CompanyRole.owner), isTrue);
      expect(kind.canView(CompanyRole.admin), isTrue);
    }
    for (final kind in ReportExportKind.values.take(6)) {
      expect(kind.canView(CompanyRole.operations), isTrue);
      expect(kind.canView(CompanyRole.viewer), isTrue);
    }
    for (final kind in ReportExportKind.values.skip(6)) {
      expect(kind.canView(CompanyRole.operations), isFalse);
      expect(kind.canView(CompanyRole.viewer), isFalse);
      expect(kind.canView(CompanyRole.accountant), isTrue);
    }
  });
}
