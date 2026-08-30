import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation_status.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/company_user.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/presentation/widgets/company_invitations_view.dart';
import 'package:horus_system/features/company/presentation/widgets/company_members_view.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  group('CompanyMembersView', () {
    testWidgets('uses desktop table on wide screens', (tester) async {
      await _setSurface(tester, const Size(1200, 800));
      await tester.pumpWidget(
        _localizedApp(
          CompanyMembersView(
            users: [_user(role: CompanyRole.viewer)],
            currentCompanyContext: _context(CompanyRole.owner),
            currentUserId: 'actor-user',
            actionInProgress: false,
            onChangeRole: (_) {},
            onDeactivate: (_) {},
            onReactivate: (_) {},
            onGrantOwnership: (_) {},
            onTransferOwnership: (_) {},
          ),
        ),
      );

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Viewer'), findsOneWidget);
    });

    testWidgets('uses adaptive cards on narrow screens', (tester) async {
      await _setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(
        _localizedApp(
          CompanyMembersView(
            users: [_user(role: CompanyRole.viewer)],
            currentCompanyContext: _context(CompanyRole.owner),
            currentUserId: 'actor-user',
            actionInProgress: false,
            onChangeRole: (_) {},
            onDeactivate: (_) {},
            onReactivate: (_) {},
            onGrantOwnership: (_) {},
            onTransferOwnership: (_) {},
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Member One'), findsOneWidget);
    });

    testWidgets('owner sees role, status and ownership actions', (tester) async {
      await _setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(
        _localizedApp(
          CompanyMembersView(
            users: [_user(role: CompanyRole.admin)],
            currentCompanyContext: _context(CompanyRole.owner),
            currentUserId: 'actor-user',
            actionInProgress: false,
            onChangeRole: (_) {},
            onDeactivate: (_) {},
            onReactivate: (_) {},
            onGrantOwnership: (_) {},
            onTransferOwnership: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Change role'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);
      expect(find.text('Grant ownership'), findsOneWidget);
      expect(find.text('Transfer ownership'), findsOneWidget);
    });

    testWidgets('admin cannot manage peer admin', (tester) async {
      await _setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(
        _localizedApp(
          CompanyMembersView(
            users: [_user(role: CompanyRole.admin)],
            currentCompanyContext: _context(CompanyRole.admin),
            currentUserId: 'actor-user',
            actionInProgress: false,
            onChangeRole: (_) {},
            onDeactivate: (_) {},
            onReactivate: (_) {},
            onGrantOwnership: (_) {},
            onTransferOwnership: (_) {},
          ),
        ),
      );

      expect(find.byType(PopupMenuButton), findsNothing);
    });

    testWidgets('inactive lower-role member exposes reactivate to admin', (
      tester,
    ) async {
      await _setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(
        _localizedApp(
          CompanyMembersView(
            users: [
              _user(role: CompanyRole.viewer, isActive: false),
            ],
            currentCompanyContext: _context(CompanyRole.admin),
            currentUserId: 'actor-user',
            actionInProgress: false,
            onChangeRole: (_) {},
            onDeactivate: (_) {},
            onReactivate: (_) {},
            onGrantOwnership: (_) {},
            onTransferOwnership: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Reactivate'), findsOneWidget);
      expect(find.text('Change role'), findsNothing);
    });
  });

  group('CompanyInvitationsView', () {
    testWidgets('wide layout renders invitation table', (tester) async {
      await _setSurface(tester, const Size(1200, 800));
      await tester.pumpWidget(
        _localizedApp(
          CompanyInvitationsView(
            invitations: [_invitation(CompanyInvitationStatus.pending)],
            actionInProgress: false,
            onResend: (_) {},
            onRevoke: (_) {},
          ),
        ),
      );

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('only pending invitation exposes resend and revoke', (
      tester,
    ) async {
      await _setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(
        _localizedApp(
          CompanyInvitationsView(
            invitations: [
              _invitation(CompanyInvitationStatus.pending),
              _invitation(
                CompanyInvitationStatus.accepted,
                id: 'accepted-invitation',
                email: 'accepted@example.com',
              ),
            ],
            actionInProgress: false,
            onResend: (_) {},
            onRevoke: (_) {},
          ),
        ),
      );

      expect(find.byType(PopupMenuButton), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();

      expect(find.text('Resend'), findsOneWidget);
      expect(find.text('Revoke'), findsOneWidget);
    });

    testWidgets('Arabic locale renders RTL invitation content', (tester) async {
      await _setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(
        _localizedApp(
          CompanyInvitationsView(
            invitations: [_invitation(CompanyInvitationStatus.pending)],
            actionInProgress: false,
            onResend: (_) {},
            onRevoke: (_) {},
          ),
          locale: const Locale('ar'),
        ),
      );

      expect(find.text('قيد الانتظار'), findsOneWidget);
      final element = tester.element(find.text('user@example.com'));
      expect(Directionality.of(element), TextDirection.rtl);
    });
  });
}

Widget _localizedApp(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company'),
    role: role,
  );
}

CompanyUser _user({
  required CompanyRole role,
  bool isActive = true,
}) {
  return CompanyUser(
    id: 'membership-1',
    companyId: 'company-1',
    userId: 'member-user',
    displayName: 'Member One',
    phone: '+971500000000',
    role: role,
    isActive: isActive,
  );
}

CompanyInvitation _invitation(
  CompanyInvitationStatus status, {
  String id = 'invitation-1',
  String email = 'user@example.com',
}) {
  return CompanyInvitation(
    id: id,
    companyId: 'company-1',
    email: email,
    role: CompanyRole.viewer,
    status: status,
    expiresAt: DateTime.utc(2026, 9, 6),
    lastSentAt: DateTime.utc(2026, 8, 30),
    sendCount: 1,
    createdAt: DateTime.utc(2026, 8, 30),
    acceptedAt: status == CompanyInvitationStatus.accepted
        ? DateTime.utc(2026, 8, 31)
        : null,
    revokedAt: status == CompanyInvitationStatus.revoked
        ? DateTime.utc(2026, 8, 31)
        : null,
  );
}
