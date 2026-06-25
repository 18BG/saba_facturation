import '../models/billing_line.dart';

class BillingValidationSummary {
  const BillingValidationSummary({
    required this.missingReferences,
    required this.duplicateReferences,
    required this.missingNames,
    required this.autreWithoutComment,
    required this.zeroBilledStaff,
    required this.zeroMonthlyRate,
  });

  final int missingReferences;
  final int duplicateReferences;
  final int missingNames;
  final int autreWithoutComment;
  final int zeroBilledStaff;
  final int zeroMonthlyRate;

  int get blockingCount =>
      missingReferences +
      duplicateReferences +
      missingNames +
      autreWithoutComment;

  int get warningCount => zeroBilledStaff + zeroMonthlyRate;

  int get totalCount => blockingCount + warningCount;

  bool get hasIssues => totalCount > 0;
}

BillingValidationSummary validateBillingLines(
  List<BillingLine> lines, {
  required int year,
}) {
  final referenceCounts = <String, int>{};
  for (final line in lines) {
    final reference = line.reference.trim().toUpperCase();
    if (reference.isEmpty) continue;
    referenceCounts[reference] = (referenceCounts[reference] ?? 0) + 1;
  }

  var missingReferences = 0;
  var duplicateReferences = 0;
  var missingNames = 0;
  var autreWithoutComment = 0;
  var zeroBilledStaff = 0;
  var zeroMonthlyRate = 0;

  for (final line in lines) {
    final reference = line.reference.trim().toUpperCase();
    if (reference.isEmpty) {
      missingReferences++;
    } else if ((referenceCounts[reference] ?? 0) > 1) {
      duplicateReferences++;
    }

    if (line.name.trim().isEmpty) missingNames++;
    if (line.status == 'Autre' && line.statusComment.trim().isEmpty) {
      autreWithoutComment++;
    }
    if (line.billedStaff == 0) zeroBilledStaff++;
    if (line.annualBilling(year).monthlyRate == 0) zeroMonthlyRate++;
  }

  return BillingValidationSummary(
    missingReferences: missingReferences,
    duplicateReferences: duplicateReferences,
    missingNames: missingNames,
    autreWithoutComment: autreWithoutComment,
    zeroBilledStaff: zeroBilledStaff,
    zeroMonthlyRate: zeroMonthlyRate,
  );
}

List<String> billingLineIssues(BillingLine line, {required int year}) {
  return [
    if (line.reference.trim().isEmpty) 'Reference comptable manquante.',
    if (line.name.trim().isEmpty) 'Nom / site manquant.',
    if (line.status == 'Autre' && line.statusComment.trim().isEmpty)
      'Statut Autre : commentaire requis.',
    if (line.billedStaff == 0) 'Eff facture a 0.',
    if (line.annualBilling(year).monthlyRate == 0) 'Tarif mensuel a 0.',
  ];
}
