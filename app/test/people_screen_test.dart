// The People screen. Decision 063: only the owner adds people or changes what
// they can do, nobody is deleted, and the office login itself cannot be
// changed from here.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/api/api_exception.dart';
import 'package:winibex_accounting/core/money/money.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/people/data/people_repository.dart';
import 'package:winibex_accounting/features/people/domain/team_member.dart';
import 'package:winibex_accounting/features/people/presentation/people_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

const _owner = TeamMember(id: 1, name: 'Office', email: 'office@winibex.com', role: 'owner');
final _maryam = TeamMember(
  id: 2,
  name: 'Maryam',
  email: 'maryam@winibex.com',
  role: 'admin',
  approvalLimit: Money.pkr(5000000),
  sharesOwnerLogin: true,
);
const _fazal = TeamMember(id: 3, name: 'Fazal', email: 'fazal@winibex.com', role: 'staff');

class _FakeRepository extends PeopleRepository {
  _FakeRepository({this.refuseAdd}) : super(dio: Dio());

  final ApiException? refuseAdd;
  TeamMemberForm? added;
  int? changedId;
  Map<String, dynamic>? changes;
  int? resetId;
  String? resetTo;

  @override
  Future<List<TeamMember>> list() async => [_owner, _maryam, _fazal];

  @override
  Future<void> add(TeamMemberForm form) async {
    if (refuseAdd != null) throw refuseAdd!;
    added = form;
  }

  @override
  Future<void> change(int id, Map<String, dynamic> changes) async {
    changedId = id;
    this.changes = changes;
  }

  @override
  Future<void> resetPassword(int id, String temporaryPassword) async {
    resetId = id;
    resetTo = temporaryPassword;
  }
}

Future<void> _pump(WidgetTester tester, _FakeRepository repository) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [peopleRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: PeopleScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(PeopleScreen)));

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('everyone is listed, and the office login has nothing to change', (tester) async {
    await _pump(tester, _FakeRepository());
    final l10n = _l10n(tester);

    expect(find.text('Office'), findsOneWidget);
    expect(find.text('Maryam'), findsOneWidget);
    expect(find.text('Fazal'), findsOneWidget);
    expect(find.text(l10n.peopleSharesLogin), findsOneWidget);
    expect(find.text(l10n.actionEdit), findsNWidgets(2),
        reason: 'the owner row offers no edit, reset or switch off');
  });

  testWidgets('what each role can do is one tap away', (tester) async {
    await _pump(tester, _FakeRepository());
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.roleHelpTitle));
    await tester.pumpAndSettle();

    expect(find.textContaining(l10n.roleOwnerHelp), findsOneWidget);
    expect(find.textContaining(l10n.roleStaffHelp), findsOneWidget);
  });

  testWidgets('adding staff sends no approval limit', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionAddPerson));
    await tester.pumpAndSettle();

    await tester.enterText(_field(l10n.fieldFullName), 'Ali');
    await tester.enterText(_field(l10n.fieldEmail), 'ali@winibex.com');
    await tester.enterText(_field(l10n.fieldTemporaryPassword), 'Welcome-2026');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSave));
    await tester.pumpAndSettle();

    expect(repository.added?.role, 'staff');
    expect(repository.added?.email, 'ali@winibex.com');
    expect(repository.added?.approvalLimit, isNull);
    expect(repository.added?.autoApproveOwn, isFalse);
    expect(find.text(l10n.personAdded), findsOneWidget);
  });

  testWidgets('an admin limit typed in rupees is sent in paisa', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionAddPerson));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l10n.fieldFullName), 'Sana');
    await tester.enterText(_field(l10n.fieldEmail), 'sana@winibex.com');
    await tester.tap(find.text(l10n.roleAdmin).last);
    await tester.pumpAndSettle();
    await tester.enterText(_field(l10n.fieldApprovalLimit), '50,000');
    await tester.enterText(_field(l10n.fieldTemporaryPassword), 'Welcome-2026');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSave));
    await tester.pumpAndSettle();

    expect(repository.added?.role, 'admin');
    expect(repository.added?.approvalLimit?.minorUnits, 5000000);
  });

  testWidgets('a short temporary password is refused before anything is sent', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionAddPerson));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l10n.fieldFullName), 'Ali');
    await tester.enterText(_field(l10n.fieldEmail), 'ali@winibex.com');
    await tester.enterText(_field(l10n.fieldTemporaryPassword), 'short');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSave));
    await tester.pumpAndSettle();

    expect(repository.added, isNull);
    expect(find.text(l10n.changePasswordTooShort), findsOneWidget);
  });

  testWidgets('a refusal from the server is shown in its own words', (tester) async {
    final repository = _FakeRepository(
      refuseAdd: const ApiException(
        code: 'ALREADY_EXISTS',
        message: 'Someone already signs in with that email.',
        status: 409,
      ),
    );
    await _pump(tester, repository);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionAddPerson));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l10n.fieldFullName), 'Ali');
    await tester.enterText(_field(l10n.fieldEmail), 'fazal@winibex.com');
    await tester.enterText(_field(l10n.fieldTemporaryPassword), 'Welcome-2026');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSave));
    await tester.pumpAndSettle();

    expect(find.text('Someone already signs in with that email.'), findsOneWidget);
  });

  testWidgets('switching someone off sends isActive false', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionSwitchOff).last);
    await tester.pumpAndSettle();

    expect(repository.changedId, 3);
    expect(repository.changes, {'isActive': false});
  });

  testWidgets('resetting a password sends the temporary one', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionResetPassword).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Temporary-2026');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionResetPassword));
    await tester.pumpAndSettle();

    expect(repository.resetId, 2);
    expect(repository.resetTo, 'Temporary-2026');
  });
}
