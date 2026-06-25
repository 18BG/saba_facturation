import 'package:facturation_app/models/billing_years.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offers recent years and the next year', () {
    expect(billingYearOptions(asOf: DateTime(2026, 6, 23)), [
      2023,
      2024,
      2025,
      2026,
      2027,
    ]);
  });
}
