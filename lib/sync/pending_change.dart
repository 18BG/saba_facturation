enum ChangeScope {
  line,
  annualBilling,
  paymentCell,
}

enum ChangeState {
  queued,
  syncing,
  synced,
  failed,
  conflict,
}

class PendingChange {
  const PendingChange({
    required this.id,
    required this.reference,
    required this.scope,
    required this.field,
    required this.value,
    required this.createdAt,
    this.year,
    this.state = ChangeState.queued,
    this.errorMessage,
  });

  final String id;
  final String reference;
  final ChangeScope scope;
  final String field;
  final Object? value;
  final DateTime createdAt;
  final int? year;
  final ChangeState state;
  final String? errorMessage;

  PendingChange copyWith({
    ChangeState? state,
    String? errorMessage,
  }) {
    return PendingChange(
      id: id,
      reference: reference,
      scope: scope,
      field: field,
      value: value,
      createdAt: createdAt,
      year: year,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
