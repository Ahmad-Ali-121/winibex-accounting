import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A date, typed or picked from a calendar. Used by the entry form, moving
/// money and paying someone back.
///
/// It was a text box only, so every date had to be typed by hand. F3. Typing
/// still works, which is how a date the calendar does not offer, such as one
/// in the future, can still be tried and refused by the server.
class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.hint,
    required this.pickTooltip,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final String hint;
  final String pickTooltip;

  /// The calendar starts at go-live: everything earlier is history, which
  /// these forms do not record. The server's books_live_from setting is the
  /// rule; this only bounds what the calendar offers.
  static final DateTime firstPickable = DateTime(2026, 7, 1);

  static String format(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Today on this device, as the forms start with.
  static String today() => format(DateTime.now());

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late final TextEditingController _text = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new form after a save starts with today's date. Without this the box
    // would keep showing the last entry's date while the draft held today's.
    if (widget.value != _text.text) _text.text = widget.value;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateField.firstPickable.isAfter(today) ? today : DateField.firstPickable;

    var initial = DateTime.tryParse(_text.text) ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(today)) initial = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today,
    );
    if (picked == null || !mounted) return;

    final value = DateField.format(picked);
    _text.text = value;
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _text,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: IconButton(
          tooltip: widget.pickTooltip,
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: _pick,
        ),
      ),
      keyboardType: TextInputType.datetime,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
      onChanged: widget.onChanged,
    );
  }
}
