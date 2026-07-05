/// Converts a two-letter ISO 3166-1 country code (e.g. `TH`, `KR`, `US`) into
/// its flag emoji by mapping each letter to a Unicode Regional Indicator
/// Symbol — no per-country lookup table needed since these compose visually
/// into the flag for any valid code.
String countryFlagEmoji(String isoCode) {
  final code = isoCode.toUpperCase();
  if (code.length != 2) return '';
  const regionalIndicatorOffset = 0x1F1E6 - 0x41; // 'A'
  final codeUnits = code.codeUnits.map(
    (unit) => unit + regionalIndicatorOffset,
  );
  return String.fromCharCodes(codeUnits);
}
