// Who may post their own entries. Decision 036, defect D4.
//
// This decides whether the entry form says "Save and post" or "Submit for
// approval". It used to be "owner or admin", which offered posting to admins
// the server would refuse.

import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/features/auth/domain/auth_user.dart';

AuthUser _user(String role, {bool autoApproveOwn = false, int? approvalLimit}) {
  return AuthUser.fromJson({
    'id': 1,
    'name': 'Someone',
    'email': 'someone@winibex.test',
    'role': role,
    'mustChangePassword': false,
    'autoApproveOwn': autoApproveOwn,
    'approvalLimit': approvalLimit,
  });
}

void main() {
  test('the owner login posts its own entries', () {
    expect(_user('owner').canPostOwnEntries, isTrue);
  });

  test('an admin with auto-approve posts their own entries', () {
    expect(_user('admin', autoApproveOwn: true).canPostOwnEntries, isTrue);
  });

  test('an admin without auto-approve submits, like staff', () {
    expect(_user('admin').canPostOwnEntries, isFalse);
    expect(_user('admin').canApprove, isTrue, reason: 'they still approve other people');
  });

  test('staff never post their own entries', () {
    expect(_user('staff', autoApproveOwn: true).canPostOwnEntries, isFalse);
  });

  test('the approval limit is read from the server', () {
    expect(_user('admin', approvalLimit: 1000000).approvalLimit, 1000000);
    expect(_user('admin').approvalLimit, isNull);
  });

  test('an older response without the new fields still reads', () {
    final user = AuthUser.fromJson({
      'id': 2,
      'name': 'Older',
      'email': 'older@winibex.test',
      'role': 'admin',
    });
    expect(user.autoApproveOwn, isFalse);
    expect(user.canPostOwnEntries, isFalse);
  });
}
