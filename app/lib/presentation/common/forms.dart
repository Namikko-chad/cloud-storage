import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import 'overlays.dart';
import '../../core/i18n.dart';

InputDecoration _decoration(BuildContext context, {String? hint, bool error = false, bool onPage = false, Widget? suffix}) {
  final hm = Hm.of(context);
  OutlineInputBorder ring(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    // Inside a card or modal the field recesses to bg; on the page it is surface (§ 1.1).
    fillColor: onPage ? HmColors.surface : HmColors.bg,
    hintText: hint,
    hintStyle: HmText.jb(hm.inputFont, color: HmColors.muted),
    // One control height (§ 10.7.4): 36 px, 48 on phones.
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: (hm.control - 2 - hm.inputFont * 1.25) / 2),
    border: ring(HmColors.border),
    enabledBorder: ring(error ? HmColors.error : HmColors.border),
    focusedBorder: ring(error ? HmColors.error : HmColors.accent),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 16, maxHeight: 32),
  );
}

/// Field wrapper (§ 10.1): uppercase top label, red `*` when required,
/// one-line error below.
class HmFormField extends StatelessWidget {
  const HmFormField({super.key, required this.label, required this.child, this.required = false, this.error, this.hint});

  final String label;
  final Widget child;
  final bool required;
  final String? error;
  final String? hint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text.rich(
        TextSpan(
          text: label.toUpperCase(),
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: HmText.label.copyWith(color: HmColors.error),
              ),
          ],
        ),
        style: HmText.label,
      ),
      const SizedBox(height: 6),
      child,
      if (error != null) ...[
        const SizedBox(height: 4),
        Text(
          error!,
          style: HmText.jb(11, color: HmColors.error),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ] else if (hint != null) ...[
        const SizedBox(height: 4),
        Text(hint!, style: HmText.jb(11, color: HmColors.muted, height: 1.5)),
      ],
    ],
  );
}

/// Text field with its label (§ 10.4).
class HmTextField extends StatefulWidget {
  const HmTextField({
    super.key,
    required this.label,
    this.controller,
    this.required = false,
    this.error,
    this.hint,
    this.placeholder,
    this.password = false,
    this.keyboard,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
    this.identifier = false,
    this.formatters,
    this.lines = 1,
  });

  final String label;
  final TextEditingController? controller;
  final bool required;
  final String? error;
  final String? hint;
  final String? placeholder;
  final bool password;
  final TextInputType? keyboard;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// Hostnames, tokens, keys: no autocorrect or capitals (M10).
  final bool identifier;
  final List<TextInputFormatter>? formatters;

  /// Visible lines; above 1 the field grows up to twice that (notes, keys).
  /// Not for passwords.
  final int lines;

  @override
  State<HmTextField> createState() => _HmTextFieldState();
}

class _HmTextFieldState extends State<HmTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return HmFormField(
      label: widget.label,
      required: widget.required,
      error: widget.error,
      hint: widget.hint,
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        obscureText: widget.password && _hidden,
        minLines: widget.lines > 1 ? widget.lines : null,
        maxLines: widget.lines > 1 ? widget.lines * 2 : 1,
        keyboardType: widget.keyboard ?? (widget.lines > 1 ? TextInputType.multiline : null),
        autocorrect: !(widget.identifier || widget.password),
        enableSuggestions: !(widget.identifier || widget.password),
        textCapitalization: TextCapitalization.none,
        inputFormatters: widget.formatters,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        style: HmText.jb(hm.inputFont),
        decoration: _decoration(
          context,
          hint: widget.placeholder,
          error: widget.error != null,
          suffix: widget.password
              ? Semantics(
                  button: true,
                  label: _hidden ? tr('Show password', 'Показать пароль') : tr('Hide password', 'Скрыть пароль'),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _hidden = !_hidden),
                      child: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16, color: HmColors.muted),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Search field of a controls bar (§ 11.1): 220×30 on desktops, full width
/// and 48 px on phones (M11).
class HmSearchField extends StatelessWidget {
  const HmSearchField({super.key, required this.controller, this.onChanged, this.onSubmitted, this.placeholder});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autocorrect: false,
      textInputAction: TextInputAction.search,
      style: HmText.jb(hm.inputFont),
      decoration: _decoration(context, hint: placeholder ?? tr('Search…', 'Поиск…'), onPage: false).copyWith(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: ((hm.mobile ? 48 : 30) - 2 - hm.inputFont * 1.25) / 2),
        prefixIcon: const Icon(Icons.search, size: 14, color: HmColors.muted),
        prefixIconConstraints: const BoxConstraints(minWidth: 32),
      ),
    );
    return hm.mobile ? field : SizedBox(width: 220, height: 30, child: field);
  }
}

/// Settings switch with its label (§ 13.1–13.2): label left, switch right,
/// the whole row is the target (48 px on phones, M13).
class HmToggleRow extends StatelessWidget {
  const HmToggleRow({super.key, required this.label, required this.value, required this.onChanged, this.hint});

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      label: label,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged!(!value) : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: hm.mobile ? 48 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: HmText.jb(12, weight: 600, spacing: 0.5)),
                        if (hint != null) ...[
                          const SizedBox(height: 2),
                          Text(hint!, style: HmText.jb(11, color: HmColors.muted, height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _Switch(value: value),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 40,
    height: 22,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(color: value ? HmColors.accent : HmColors.border, borderRadius: BorderRadius.circular(11)),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 200),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    ),
  );
}

/// Checkbox row, committed on submit (§ 13.6).
class HmCheckRow extends StatelessWidget {
  const HmCheckRow({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return Semantics(
      checked: value,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: hm.mobile ? 48 : 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: value ? HmColors.accent : HmColors.bg,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: value ? HmColors.accent : HmColors.border),
                  ),
                  child: value ? const Icon(Icons.check, size: 11, color: HmColors.onAccent) : null,
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(label, style: HmText.jb(12))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One of a few short options, all visible (§ 13.5); full width on phones.
class HmSegmented<T> extends StatelessWidget {
  const HmSegmented({super.key, required this.options, required this.value, required this.onChanged});

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final items = [
      for (final e in options.entries) _Segment(label: e.value, active: e.key == value, onTap: () => onChanged(e.key), expand: hm.mobile),
    ];
    return Container(
      height: hm.mobile ? 40 : 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: HmColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HmColors.border),
      ),
      child: Row(
        mainAxisSize: hm.mobile ? MainAxisSize.max : MainAxisSize.min,
        children: [for (final i in items) hm.mobile ? Expanded(child: i) : i],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.active, required this.onTap, required this.expand});

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: active,
    button: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? HmColors.tint(HmColors.accent, HmColors.resting) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? HmColors.tint(HmColors.accent, HmColors.ring) : Colors.transparent),
          ),
          child: Text(label, style: HmText.button.copyWith(color: active ? HmColors.accent : HmColors.muted)),
        ),
      ),
    ),
  );
}

/// Select (§ 10.6): a pixel twin of the text field. Opens a dropdown panel
/// on desktops and a picker sheet on phones (App. D), with a search field
/// from 8 options on (§ 16.4).
class HmSelect<T> extends StatelessWidget {
  const HmSelect({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.placeholder,
    this.hint,
    this.describe,
    this.showLabel = true,
  });

  final String label;
  final bool showLabel; // false: a bare control (sort bar)
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final bool required;
  final String? placeholder;
  final String? hint;
  final String Function(T)? describe;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final text = value == null ? null : options[value];
    final field = Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            final v = await pickOption<T>(context, title: label, options: options, value: value, describe: describe);
            if (v != null) onChanged(v);
          },
          child: InputDecorator(
            decoration: _decoration(context, suffix: const Icon(Icons.expand_more, size: 16, color: HmColors.muted)),
            child: Text(
              text ?? placeholder ?? tr('Choose…', 'Выберите…'),
              style: HmText.jb(hm.inputFont, color: text == null ? HmColors.muted : HmColors.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
    if (!showLabel) return field;
    return HmFormField(label: label, required: required, hint: hint, child: field);
  }
}
