import 'package:flutter/material.dart';

// A lightweight, consistent button wrapper that delegates to the appropriate
// Material button type. This helps enforce a world-class, cohesive look
// across the app while keeping usage simple.
enum ButtonVariant { primary, secondary, outline, text }

class WorldClassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;

  const WorldClassButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w700);

    switch (variant) {
      case ButtonVariant.outline:
        if (icon != null) {
          return OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, style: textStyle),
          );
        }
        return OutlinedButton(
          onPressed: onPressed,
          child: Text(label, style: textStyle),
        );
      case ButtonVariant.text:
        if (icon != null) {
          return TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, style: textStyle),
          );
        }
        return TextButton(
          onPressed: onPressed,
          child: Text(label, style: textStyle),
        );
      case ButtonVariant.secondary:
      case ButtonVariant.primary:
      default:
        if (icon != null) {
          return ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, style: textStyle),
          );
        }
        return ElevatedButton(
          onPressed: onPressed,
          child: Text(label, style: textStyle),
        );
    }
  }
}
