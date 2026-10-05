import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';

/// A tidy colour picker: shows the current colour, opens a small dialog with
/// curated presets, hue/saturation/brightness sliders and a hex-code field.
class ColorField extends StatelessWidget {
  const ColorField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;

  /// Current colour as "#RRGGBB".
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = parseHex(value);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (_) => _ColorPickerDialog(initial: value, title: label),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
        ),
        child: Text(value.toUpperCase()),
      ),
    );
  }
}

/// Converts "#RRGGBB" into a Flutter Color (falls back to navy).
Color parseHex(String hex) {
  final clean = hex.trim().replaceAll('#', '');
  if (clean.length != 6) return const Color(0xFF173B63);
  try {
    return Color(int.parse(clean, radix: 16) + 0xFF000000);
  } catch (_) {
    return const Color(0xFF173B63);
  }
}

/// Shows a colour as "#rrggbb".
String toHex(Color color) {
  final r = color.red.toRadixString(16).padLeft(2, '0');
  final g = color.green.toRadixString(16).padLeft(2, '0');
  final b = color.blue.toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

/// Curated preset colours offered in the picker.
const List<String> kColorPresets = [
  '#173B63', // deep navy (brand default)
  '#0FA3B1', // teal
  '#C9A227', // gold
  '#7B2D26', // maroon
  '#1E7A4D', // forest green
  '#5B3E96', // royal purple
  '#21252B', // charcoal
  '#C4622D', // terracotta
];

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, required this.title});

  final String initial;
  final String title;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(parseHex(widget.initial));
  late final TextEditingController _hex =
      TextEditingController(text: widget.initial.toUpperCase());

  void _setFromHex(String text) {
    if (Validators.isValidHexColor(text)) {
      setState(() {
        _hsv = HSVColor.fromColor(parseHex(text));
      });
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    return AlertDialog(
      title: Text('Pick ${widget.title.toLowerCase()}'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live preview square.
              Container(
                height: 72,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Preset swatches.
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final preset in kColorPresets)
                    GestureDetector(
                      onTap: () => setState(() {
                        _hsv = HSVColor.fromColor(parseHex(preset));
                        _hex.text = preset.toUpperCase();
                      }),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: parseHex(preset),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _hex.text.toUpperCase() == preset.toUpperCase()
                                ? Colors.black
                                : Colors.black12,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Hue', style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: _hsv.hue,
                max: 360,
                onChanged: (v) => setState(() {
                  _hsv = _hsv.withHue(v);
                  _hex.text = toHex(_hsv.toColor()).toUpperCase();
                }),
              ),
              Text('Saturation', style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: _hsv.saturation,
                onChanged: (v) => setState(() {
                  _hsv = _hsv.withSaturation(v);
                  _hex.text = toHex(_hsv.toColor()).toUpperCase();
                }),
              ),
              Text('Brightness', style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: _hsv.value,
                onChanged: (v) => setState(() {
                  _hsv = _hsv.withValue(v);
                  _hex.text = toHex(_hsv.toColor()).toUpperCase();
                }),
              ),
              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: _hex,
                decoration: const InputDecoration(
                  labelText: 'Hex code',
                  hintText: '#173B63',
                ),
                onChanged: _setFromHex,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(toHex(color)),
          child: const Text('Use colour'),
        ),
      ],
    );
  }
}
