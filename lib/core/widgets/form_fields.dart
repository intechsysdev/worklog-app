import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Field label: 14/600, with an optional muted hint.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Text.rich(
      TextSpan(
        text: text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
        children: [
          if (hint != null)
            TextSpan(
              text: ' $hint',
              style: TextStyle(fontWeight: FontWeight.w400, color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}

/// Tappable field that shows a value and opens a picker (date or time), 52 px high.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon = Icons.schedule_rounded,
    this.placeholder = 'Elegir',
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData icon;
  final String placeholder;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final borderColor = errorText != null ? c.primaryDark : c.borderInput;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: '$label: ${value ?? placeholder}',
          child: Material(
            color: enabled ? c.surface : c.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              side: BorderSide(color: borderColor),
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.input)),
              onTap: enabled ? onTap : null,
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: ExcludeSemantics(
                          child: Text(
                            value ?? placeholder,
                            style: TextStyle(fontSize: 16, color: value == null ? c.inkMuted : c.ink),
                          ),
                        ),
                      ),
                      Icon(icon, size: 20, color: c.inkMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: TextStyle(fontSize: 13, color: c.primaryDark)),
        ],
      ],
    );
  }
}

/// Single-line text field with a label.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.labelHint,
    this.errorText,
    this.onChanged,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? labelHint;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldLabel(label, hint: labelHint),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        onChanged: onChanged,
        maxLength: maxLength,
        style: TextStyle(fontSize: 16, color: context.wl.ink),
        decoration: InputDecoration(hintText: hint, errorText: errorText, counterText: ''),
      ),
    ],
  );
}
