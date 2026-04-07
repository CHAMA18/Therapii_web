import 'package:flutter/material.dart';

class MarkdownTextEditingController extends TextEditingController {
  MarkdownTextEditingController({String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final defaultStyle = style ?? const TextStyle();
    final List<TextSpan> spans = [];

    final textStr = value.text;
    if (textStr.isEmpty) {
      return TextSpan(style: defaultStyle, text: textStr);
    }

    final regex = RegExp(
        r'(\*\*(.*?)\*\*)|(\*(.*?)\*)|(^(#+)\s+(.*)$)|(^>\s+(.*)$)|(\[(.*?)\]\((.*?)\))',
        multiLine: true);

    int start = 0;
    for (final match in regex.allMatches(textStr)) {
      if (match.start > start) {
        spans.add(TextSpan(text: textStr.substring(start, match.start), style: defaultStyle));
      }

      if (match.group(1) != null) {
        // Bold: **text**
        spans.add(TextSpan(
          text: match.group(1),
          style: defaultStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(3) != null) {
        // Italic: *text*
        spans.add(TextSpan(
          text: match.group(3),
          style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(5) != null) {
        // Header: # text
        final hashes = match.group(6)!;
        double fontSize = defaultStyle.fontSize ?? 16;
        if (hashes.length == 1) fontSize += 8;
        else if (hashes.length == 2) fontSize += 6;
        else if (hashes.length == 3) fontSize += 4;
        
        spans.add(TextSpan(
          text: match.group(5),
          style: defaultStyle.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(8) != null) {
        // Quote: > text
        spans.add(TextSpan(
          text: match.group(8),
          style: defaultStyle.copyWith(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(10) != null) {
        // Link: [text](link)
        spans.add(TextSpan(
          text: match.group(10),
          style: defaultStyle.copyWith(color: Colors.blue),
        ));
      }

      start = match.end;
    }

    if (start < textStr.length) {
      spans.add(TextSpan(text: textStr.substring(start), style: defaultStyle));
    }

    return TextSpan(style: defaultStyle, children: spans);
  }
}
