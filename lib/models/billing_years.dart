List<int> billingYearOptions({DateTime? asOf}) {
  final currentYear = (asOf ?? DateTime.now()).year;
  return [
    for (var year = currentYear - 3; year <= currentYear + 1; year++) year,
  ];
}
