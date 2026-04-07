import 'package:flutter/material.dart';

enum DateTimeInputMode { date, time, dateTime, monthYear }

class DateTimeInput extends StatefulWidget {
  final String label;
  final DateTimeInputMode mode;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? helperText;

  const DateTimeInput({
    Key? key,
    required this.label,
    this.mode = DateTimeInputMode.date,
    this.initialValue,
    this.onChanged,
    this.helperText,
  }) : super(key: key);

  @override
  State<DateTimeInput> createState() => _DateTimeInputState();
}

class _DateTimeInputState extends State<DateTimeInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant DateTimeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) => '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.year}';

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    if (widget.mode == DateTimeInputMode.date ||
        widget.mode == DateTimeInputMode.monthYear) {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        String value;
        if (widget.mode == DateTimeInputMode.monthYear) {
          value = '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        } else {
          value = _formatDate(picked);
        }
        _controller.text = value;
        widget.onChanged?.call(value);
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (picked != null) {
      final value = _formatTime(picked);
      _controller.text = value;
      widget.onChanged?.call(value);
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final value = '${_formatDate(dt)} ${_formatTime(time)}';
    _controller.text = value;
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: _suffixIcon(),
        helperText: widget.helperText,
      ),
      onTap: () {
        switch (widget.mode) {
          case DateTimeInputMode.date:
          case DateTimeInputMode.monthYear:
            _pickDate();
            break;
          case DateTimeInputMode.time:
            _pickTime();
            break;
          case DateTimeInputMode.dateTime:
            _pickDateTime();
            break;
        }
      },
    );
  }

  Widget _suffixIcon() {
    switch (widget.mode) {
      case DateTimeInputMode.date:
      case DateTimeInputMode.monthYear:
        return const Icon(Icons.calendar_today);
      case DateTimeInputMode.time:
        return const Icon(Icons.access_time);
      case DateTimeInputMode.dateTime:
        return const Icon(Icons.calendar_today);
    }
  }
}
