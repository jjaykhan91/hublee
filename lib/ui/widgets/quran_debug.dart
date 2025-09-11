import 'package:flutter/material.dart';

/// --- Minimal catalog of Arabic/Qur’anic marks (expand if you find more) ---
const Map<int, String> _name = {
  0x06DD: 'ARABIC END OF AYAH (۝)',
  0x06DE: 'ARABIC START OF RUB EL HIZB (۞)',
  0x06DF: 'SMALL HIGH ROUNDED ZERO (۟) [COMBINING]',
  0x06E0: 'SMALL HIGH UPRIGHT RECTANGULAR ZERO (۠) [COMBINING]',
  0x06E2: 'SMALL HIGH MEEM (ۢ) [COMBINING]',
  0x06E7: 'SMALL HIGH YEH (ۧ) [COMBINING]',
  0x06E8: 'SMALL HIGH WAW (ۨ) [COMBINING]',
  0x0670: 'SUPERSCRIPT ALEF (ٰ) [COMBINING]',
  0x064B: 'FATHATAN (ً) [COMBINING]',
  0x064C: 'DAMMATAN (ٌ) [COMBINING]',
  0x064D: 'KASRATAN (ٍ) [COMBINING]',
  0x064E: 'FATHA (َ) [COMBINING]',
  0x064F: 'DAMMA (ُ) [COMBINING]',
  0x0650: 'KASRA (ِ) [COMBINING]',
  0x0651: 'SHADDA (ّ) [COMBINING]',
  0x0652: 'SUKUN (ْ) [COMBINING]',
  0x06D6: 'SMALL HIGH LIGATURE ṢAD LAM ALEF',
  0x06D7: 'SMALL HIGH LIGATURE QAF LAM ALEF',
  0x06D8: 'SMALL HIGH MEEM ISOLATED FORM',
  0x06D9: 'SMALL HIGH LAM ALEF',
  0x06DA: 'SMALL HIGH JEEM',
  0x06DB: 'SMALL HIGH THREE DOTS',
  0x06DC: 'SMALL HIGH SEEN',
  0x06E5: 'SMALL WAW',
  0x06E6: 'SMALL YEH',
  0x08F0: 'ARABIC OPEN FATHATAN',
  0x08F1: 'ARABIC OPEN DAMMATAN',
  0x08F2: 'ARABIC OPEN KASRATAN',
  0x25CC: 'DOTTED CIRCLE (placeholder)',
};

bool _isCombining(int cp) =>
    cp == 0x0670 || (cp >= 0x064B && cp <= 0x0652) ||
    cp == 0x06DF || cp == 0x06E0 || cp == 0x06E2 || cp == 0x06E7 || cp == 0x06E8;

String _cpName(int cp) {
  final n = _name[cp];
  final hex = 'U+${cp.toRadixString(16).toUpperCase().padLeft(4, '0')}';
  return n == null ? hex : '$hex · $n';
}

/// Console logger: prints every rune with hex and friendly name.
void debugRunesDetailed(String s, {String label = 'TEXT'}) {
  final sb = StringBuffer('$label runes (${s.runes.length}):\n');
  final runes = s.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    final cp = runes[i];
    final ch = String.fromCharCode(cp);
    sb.writeln('${i.toString().padLeft(3)}  ${_cpName(cp).padRight(38)}  "$ch"');
  }
  // ignore: avoid_print
  print(sb.toString());
}

/// Visual inspector widget (optional, for on-screen debugging).
class QuranInspector extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final double badgeScale;
  const QuranInspector({
    super.key,
    required this.text,
    this.baseStyle,
    this.badgeScale = .78,
  });

  Color _badge(int cp) {
    if (cp == 0x06DD || cp == 0x06DE) return Colors.redAccent; // strip
    if (cp == 0x25CC) return Colors.orange;                     // placeholder
    if (_isCombining(cp)) return Colors.green;                  // combining
    if ((cp >= 0x06D6 && cp <= 0x06ED) || (cp >= 0x08D3 && cp <= 0x08FF)) {
      return Colors.lightBlue;                                  // spacing signs
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ?? Theme.of(context).textTheme.titleLarge!;
    final runes = text.runes.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          text: TextSpan(text: text, style: style),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          textDirection: TextDirection.rtl,
          alignment: WrapAlignment.end,
          children: List.generate(runes.length, (i) {
            final cp = runes[i];
            final ch = String.fromCharCode(cp);
            final hex = 'U+${cp.toRadixString(16).toUpperCase().padLeft(4, '0')}';
            final label = _name[cp] != null ? ' · ${_name[cp]!}' : '';
            final color = _badge(cp);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(ch, style: style),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: badgeScale,
                  child: Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    backgroundColor: color.withOpacity(.15),
                    side: BorderSide(color: color),
                    label: Text('$hex$label',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: color,
                        )),
                  ),
                ),
              ]),
            );
          }),
        ),
      ],
    );
  }
}
