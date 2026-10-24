const List<String> _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

String toBnDigits(String input) {
  final buf = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0x30 && unit <= 0x39) {
      buf.write(_bnDigits[unit - 0x30]);
    } else {
      buf.writeCharCode(unit);
    }
  }
  return buf.toString();
}

extension BnNumFormat on num {
  String toBnFixed(int fractionDigits) => toBnDigits(toStringAsFixed(fractionDigits));
}