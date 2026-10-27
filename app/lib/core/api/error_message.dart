import 'api_exception.dart';

/// The sentence to show when the server refuses something.
///
/// A refusal the server explains (400, 403, 404, 409) is shown in the
/// server's own words, because they name the actual problem: "That leaves
/// petty cash below zero. It holds PKR 9,700 today." A fixed label in
/// app_en.arb cannot carry the figure. The server keeps those messages safe to
/// show, with no SQL, paths or stack traces (api/core/errors.js), and the
/// change-password screen already shows them the same way.
///
/// No answer at all, or a failure on the server's side, gets the app's own
/// wording instead, passed in from app_en.arb by the caller.
///
/// Defect D3: before this, a refused save or approval showed nothing at all.
String errorMessageFor(
  Object error, {
  required String network,
  required String server,
  String? unreadable,
}) {
  final failure = ApiException.from(error);

  if (failure.isNetwork) return network;
  // The server answered and the app could not read it. Not the connection,
  // and not a refusal. F6b.
  if (failure.isUnreadable) return unreadable ?? server;

  final status = failure.status;
  if (status == null || status >= 500) return server;
  if (failure.message.trim().isEmpty || failure.message == 'Request failed.') return server;

  return failure.message;
}
