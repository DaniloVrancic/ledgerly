// Search and title matching ignore case and Bosnian diacritics, so "cevapi" finds "Ćevapi".

String fold(String? text) => (text ?? '')
    .toLowerCase()
    .replaceAll(RegExp('[čć]'), 'c')
    .replaceAll('đ', 'd')
    .replaceAll('š', 's')
    .replaceAll('ž', 'z')
    .trim();

/// "12", "12.5" and "12,50" are amounts in minor units. Anything else is null.
int? amountQuery(String query) {
  final t = query.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(t)) return null;
  return (double.parse(t) * 100).round();
}
