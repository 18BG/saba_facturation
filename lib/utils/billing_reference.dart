import '../models/billing_line.dart';

/// Returns the next human-readable billing reference for an Odoo client.
///
/// The Odoo identifier is kept as the stable client key, while the suffix
/// identifies the billing line for that client: `1867-1`, `1867-2`, etc.
String nextBillingReference(
  String odooId,
  Iterable<BillingLine> lines, {
  String? excludingLineId,
}) {
  final normalizedOdooId = odooId.trim();
  if (normalizedOdooId.isEmpty) return '';

  final pattern = RegExp(
    '^${RegExp.escape(normalizedOdooId)}-(\\d+)\$',
    caseSensitive: false,
  );
  var maxSuffix = 0;

  for (final line in lines) {
    if (excludingLineId != null && line.id == excludingLineId) continue;
    final match = pattern.firstMatch(line.reference.trim());
    final suffix = int.tryParse(match?.group(1) ?? '');
    if (suffix != null && suffix > maxSuffix) maxSuffix = suffix;
  }

  return '$normalizedOdooId-${maxSuffix + 1}';
}

bool isGeneratedBillingReference(String reference, String odooId) {
  final normalizedReference = reference.trim();
  final normalizedOdooId = odooId.trim();
  if (normalizedReference.isEmpty || normalizedOdooId.isEmpty) return false;
  return RegExp(
    '^${RegExp.escape(normalizedOdooId)}-\\d+\$',
    caseSensitive: false,
  ).hasMatch(normalizedReference);
}
