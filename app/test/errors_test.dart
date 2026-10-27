// What the app says when something goes wrong. Defect F6b: an answer the app
// could not read was reported as "Could not reach the server".

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/api/api_exception.dart';
import 'package:winibex_accounting/core/api/error_message.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/core/widgets/error_panel.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

Object _typeError() {
  try {
    const Object? missing = null;
    return (missing as String).length;
  } catch (error) {
    return error;
  }
}

void main() {
  test('an answer that cannot be read is not a lost connection', () {
    final failure = ApiException.from(_typeError());
    expect(failure.isUnreadable, isTrue);
    expect(failure.isNetwork, isFalse);
  });

  test('no answer at all is still a lost connection', () {
    final failure = ApiException.from(
      DioException(requestOptions: RequestOptions(path: '/approvals')),
    );
    expect(failure.isNetwork, isTrue);
    expect(failure.isUnreadable, isFalse);
  });

  test('a refusal the server explains is neither', () {
    const failure = ApiException(code: 'FORBIDDEN', message: 'No.', status: 403);
    expect(failure.isNetwork, isFalse);
    expect(failure.isUnreadable, isFalse);
  });

  test('errorMessageFor uses its own words for an unreadable answer', () {
    expect(
      errorMessageFor(_typeError(), network: 'net', server: 'srv', unreadable: 'unread'),
      'unread',
    );
    expect(errorMessageFor(_typeError(), network: 'net', server: 'srv'), 'srv');
  });

  testWidgets('the error panel says the answer could not be read', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ErrorPanel.from(
            _typeError(),
            networkMessage: 'Could not reach the server.',
            serverMessage: 'Something went wrong.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.errUnreadable), findsOneWidget);
    expect(find.text('Could not reach the server.'), findsNothing);
  });
}
