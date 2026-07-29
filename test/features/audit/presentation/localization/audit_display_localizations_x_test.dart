import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/presentation/localization/audit_display_localizations_x.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('localizes known audit roles and actions in English', (
    tester,
  ) async {
    final values = await _localizedValues(tester, const Locale('en'));

    expect(values.accountantRole, 'Accountant');
    expect(values.createdAction, 'Created');
    expect(values.updatedAction, 'Updated');
    expect(values.deactivatedAction, 'Deactivated');
    expect(values.reactivatedAction, 'Reactivated');
    expect(values.statusChangedAction, 'Status changed');
  });

  testWidgets('localizes known audit roles and actions in Arabic', (
    tester,
  ) async {
    final values = await _localizedValues(tester, const Locale('ar'));

    expect(values.accountantRole, 'المحاسب');
    expect(values.createdAction, 'تم الإنشاء');
    expect(values.updatedAction, 'تم التعديل');
    expect(values.deactivatedAction, 'تم التعطيل');
    expect(values.reactivatedAction, 'تم التفعيل');
    expect(values.statusChangedAction, 'تم تغيير الحالة');
  });

  testWidgets('normalizes known values and hides unknown internal values', (
    tester,
  ) async {
    late String normalizedRole;
    late String normalizedAction;
    late String unknownRole;
    late String unknownAction;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            normalizedRole = l10n.auditRoleDisplayLabel('  AcCoUnTaNt  ');
            normalizedAction = l10n.auditActionValueDisplayLabel(
              '  STATUS_CHANGED  ',
            );
            unknownRole = l10n.auditRoleDisplayLabel('legacy_supervisor');
            unknownAction = l10n.auditActionValueDisplayLabel('legacy_action');
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();

    expect(normalizedRole, 'Accountant');
    expect(normalizedAction, 'Status changed');
    expect(unknownRole, 'Not available');
    expect(unknownAction, 'Not available');
    expect(unknownRole, isNot('legacy_supervisor'));
    expect(unknownAction, isNot('legacy_action'));
  });
}

Future<_LocalizedAuditValues> _localizedValues(
  WidgetTester tester,
  Locale locale,
) async {
  late _LocalizedAuditValues values;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          values = _LocalizedAuditValues(
            accountantRole: l10n.auditRoleDisplayLabel('accountant'),
            createdAction: l10n.auditActionDisplayLabel(AuditAction.created),
            updatedAction: l10n.auditActionDisplayLabel(AuditAction.updated),
            deactivatedAction: l10n.auditActionDisplayLabel(
              AuditAction.deactivated,
            ),
            reactivatedAction: l10n.auditActionDisplayLabel(
              AuditAction.reactivated,
            ),
            statusChangedAction: l10n.auditActionDisplayLabel(
              AuditAction.statusChanged,
            ),
          );
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();

  return values;
}

class _LocalizedAuditValues {
  final String accountantRole;
  final String createdAction;
  final String updatedAction;
  final String deactivatedAction;
  final String reactivatedAction;
  final String statusChangedAction;

  const _LocalizedAuditValues({
    required this.accountantRole,
    required this.createdAction,
    required this.updatedAction,
    required this.deactivatedAction,
    required this.reactivatedAction,
    required this.statusChangedAction,
  });
}
