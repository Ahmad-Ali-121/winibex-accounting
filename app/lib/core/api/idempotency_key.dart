import 'dart:math';

/// A key for a money-creating request.
///
/// Generated once when the form opens, not when Save is pressed. A double tap,
/// or a reply that never arrived and a retry, then carries the same key and
/// the server returns the first answer instead of posting a second expense.
/// Decision 024.
///
/// Version 4, as the API requires. Random.secure is used because a predictable
/// key could let one request replay another's answer.
String newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant

  String hex(int start, int end) =>
      bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
