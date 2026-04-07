import 'package:flutter/material.dart';

class JournalInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int? maxLines;
  final bool expands;
  final TextInputType keyboardType;
  final bool readOnly;

  const JournalInputField({
    Key? key,
    required this.controller,
    this.hint = '',
    this.minLines = 4,
    this.maxLines,
    this.expands = false,
    this.keyboardType = TextInputType.multiline,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      expands: expands,
      readOnly: readOnly,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        hintText: hint,
      ),
      style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.black87),
    );
  }
}
