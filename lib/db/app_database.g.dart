// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BillingLineRecordsTable extends BillingLineRecords
    with TableInfo<$BillingLineRecordsTable, BillingLineRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillingLineRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activityMeta = const VerificationMeta(
    'activity',
  );
  @override
  late final GeneratedColumn<String> activity = GeneratedColumn<String>(
    'activity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contractNatureMeta = const VerificationMeta(
    'contractNature',
  );
  @override
  late final GeneratedColumn<String> contractNature = GeneratedColumn<String>(
    'contract_nature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _billedStaffMeta = const VerificationMeta(
    'billedStaff',
  );
  @override
  late final GeneratedColumn<int> billedStaff = GeneratedColumn<int>(
    'billed_staff',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paidStaffMeta = const VerificationMeta(
    'paidStaff',
  );
  @override
  late final GeneratedColumn<int> paidStaff = GeneratedColumn<int>(
    'paid_staff',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Actif'),
  );
  static const VerificationMeta _statusCommentMeta = const VerificationMeta(
    'statusComment',
  );
  @override
  late final GeneratedColumn<String> statusComment = GeneratedColumn<String>(
    'status_comment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    reference,
    name,
    activity,
    startDate,
    endDate,
    contractNature,
    billedStaff,
    paidStaff,
    status,
    statusComment,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'billing_line_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillingLineRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('activity')) {
      context.handle(
        _activityMeta,
        activity.isAcceptableOrUnknown(data['activity']!, _activityMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('contract_nature')) {
      context.handle(
        _contractNatureMeta,
        contractNature.isAcceptableOrUnknown(
          data['contract_nature']!,
          _contractNatureMeta,
        ),
      );
    }
    if (data.containsKey('billed_staff')) {
      context.handle(
        _billedStaffMeta,
        billedStaff.isAcceptableOrUnknown(
          data['billed_staff']!,
          _billedStaffMeta,
        ),
      );
    }
    if (data.containsKey('paid_staff')) {
      context.handle(
        _paidStaffMeta,
        paidStaff.isAcceptableOrUnknown(data['paid_staff']!, _paidStaffMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('status_comment')) {
      context.handle(
        _statusCommentMeta,
        statusComment.isAcceptableOrUnknown(
          data['status_comment']!,
          _statusCommentMeta,
        ),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  BillingLineRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillingLineRecord(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      activity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      contractNature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_nature'],
      )!,
      billedStaff: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}billed_staff'],
      )!,
      paidStaff: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_staff'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      statusComment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_comment'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BillingLineRecordsTable createAlias(String alias) {
    return $BillingLineRecordsTable(attachedDatabase, alias);
  }
}

class BillingLineRecord extends DataClass
    implements Insertable<BillingLineRecord> {
  final String localId;
  final String reference;
  final String name;
  final String activity;
  final String startDate;
  final String endDate;
  final String contractNature;
  final int billedStaff;
  final int paidStaff;
  final String status;
  final String statusComment;
  final String syncState;
  final DateTime updatedAt;
  const BillingLineRecord({
    required this.localId,
    required this.reference,
    required this.name,
    required this.activity,
    required this.startDate,
    required this.endDate,
    required this.contractNature,
    required this.billedStaff,
    required this.paidStaff,
    required this.status,
    required this.statusComment,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['reference'] = Variable<String>(reference);
    map['name'] = Variable<String>(name);
    map['activity'] = Variable<String>(activity);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['contract_nature'] = Variable<String>(contractNature);
    map['billed_staff'] = Variable<int>(billedStaff);
    map['paid_staff'] = Variable<int>(paidStaff);
    map['status'] = Variable<String>(status);
    map['status_comment'] = Variable<String>(statusComment);
    map['sync_state'] = Variable<String>(syncState);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BillingLineRecordsCompanion toCompanion(bool nullToAbsent) {
    return BillingLineRecordsCompanion(
      localId: Value(localId),
      reference: Value(reference),
      name: Value(name),
      activity: Value(activity),
      startDate: Value(startDate),
      endDate: Value(endDate),
      contractNature: Value(contractNature),
      billedStaff: Value(billedStaff),
      paidStaff: Value(paidStaff),
      status: Value(status),
      statusComment: Value(statusComment),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory BillingLineRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillingLineRecord(
      localId: serializer.fromJson<String>(json['localId']),
      reference: serializer.fromJson<String>(json['reference']),
      name: serializer.fromJson<String>(json['name']),
      activity: serializer.fromJson<String>(json['activity']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      contractNature: serializer.fromJson<String>(json['contractNature']),
      billedStaff: serializer.fromJson<int>(json['billedStaff']),
      paidStaff: serializer.fromJson<int>(json['paidStaff']),
      status: serializer.fromJson<String>(json['status']),
      statusComment: serializer.fromJson<String>(json['statusComment']),
      syncState: serializer.fromJson<String>(json['syncState']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'reference': serializer.toJson<String>(reference),
      'name': serializer.toJson<String>(name),
      'activity': serializer.toJson<String>(activity),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'contractNature': serializer.toJson<String>(contractNature),
      'billedStaff': serializer.toJson<int>(billedStaff),
      'paidStaff': serializer.toJson<int>(paidStaff),
      'status': serializer.toJson<String>(status),
      'statusComment': serializer.toJson<String>(statusComment),
      'syncState': serializer.toJson<String>(syncState),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BillingLineRecord copyWith({
    String? localId,
    String? reference,
    String? name,
    String? activity,
    String? startDate,
    String? endDate,
    String? contractNature,
    int? billedStaff,
    int? paidStaff,
    String? status,
    String? statusComment,
    String? syncState,
    DateTime? updatedAt,
  }) => BillingLineRecord(
    localId: localId ?? this.localId,
    reference: reference ?? this.reference,
    name: name ?? this.name,
    activity: activity ?? this.activity,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    contractNature: contractNature ?? this.contractNature,
    billedStaff: billedStaff ?? this.billedStaff,
    paidStaff: paidStaff ?? this.paidStaff,
    status: status ?? this.status,
    statusComment: statusComment ?? this.statusComment,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BillingLineRecord copyWithCompanion(BillingLineRecordsCompanion data) {
    return BillingLineRecord(
      localId: data.localId.present ? data.localId.value : this.localId,
      reference: data.reference.present ? data.reference.value : this.reference,
      name: data.name.present ? data.name.value : this.name,
      activity: data.activity.present ? data.activity.value : this.activity,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      contractNature: data.contractNature.present
          ? data.contractNature.value
          : this.contractNature,
      billedStaff: data.billedStaff.present
          ? data.billedStaff.value
          : this.billedStaff,
      paidStaff: data.paidStaff.present ? data.paidStaff.value : this.paidStaff,
      status: data.status.present ? data.status.value : this.status,
      statusComment: data.statusComment.present
          ? data.statusComment.value
          : this.statusComment,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillingLineRecord(')
          ..write('localId: $localId, ')
          ..write('reference: $reference, ')
          ..write('name: $name, ')
          ..write('activity: $activity, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('contractNature: $contractNature, ')
          ..write('billedStaff: $billedStaff, ')
          ..write('paidStaff: $paidStaff, ')
          ..write('status: $status, ')
          ..write('statusComment: $statusComment, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    reference,
    name,
    activity,
    startDate,
    endDate,
    contractNature,
    billedStaff,
    paidStaff,
    status,
    statusComment,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillingLineRecord &&
          other.localId == this.localId &&
          other.reference == this.reference &&
          other.name == this.name &&
          other.activity == this.activity &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.contractNature == this.contractNature &&
          other.billedStaff == this.billedStaff &&
          other.paidStaff == this.paidStaff &&
          other.status == this.status &&
          other.statusComment == this.statusComment &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class BillingLineRecordsCompanion extends UpdateCompanion<BillingLineRecord> {
  final Value<String> localId;
  final Value<String> reference;
  final Value<String> name;
  final Value<String> activity;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<String> contractNature;
  final Value<int> billedStaff;
  final Value<int> paidStaff;
  final Value<String> status;
  final Value<String> statusComment;
  final Value<String> syncState;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BillingLineRecordsCompanion({
    this.localId = const Value.absent(),
    this.reference = const Value.absent(),
    this.name = const Value.absent(),
    this.activity = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.contractNature = const Value.absent(),
    this.billedStaff = const Value.absent(),
    this.paidStaff = const Value.absent(),
    this.status = const Value.absent(),
    this.statusComment = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillingLineRecordsCompanion.insert({
    required String localId,
    this.reference = const Value.absent(),
    this.name = const Value.absent(),
    this.activity = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.contractNature = const Value.absent(),
    this.billedStaff = const Value.absent(),
    this.paidStaff = const Value.absent(),
    this.status = const Value.absent(),
    this.statusComment = const Value.absent(),
    this.syncState = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       updatedAt = Value(updatedAt);
  static Insertable<BillingLineRecord> custom({
    Expression<String>? localId,
    Expression<String>? reference,
    Expression<String>? name,
    Expression<String>? activity,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? contractNature,
    Expression<int>? billedStaff,
    Expression<int>? paidStaff,
    Expression<String>? status,
    Expression<String>? statusComment,
    Expression<String>? syncState,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (reference != null) 'reference': reference,
      if (name != null) 'name': name,
      if (activity != null) 'activity': activity,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (contractNature != null) 'contract_nature': contractNature,
      if (billedStaff != null) 'billed_staff': billedStaff,
      if (paidStaff != null) 'paid_staff': paidStaff,
      if (status != null) 'status': status,
      if (statusComment != null) 'status_comment': statusComment,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillingLineRecordsCompanion copyWith({
    Value<String>? localId,
    Value<String>? reference,
    Value<String>? name,
    Value<String>? activity,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<String>? contractNature,
    Value<int>? billedStaff,
    Value<int>? paidStaff,
    Value<String>? status,
    Value<String>? statusComment,
    Value<String>? syncState,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BillingLineRecordsCompanion(
      localId: localId ?? this.localId,
      reference: reference ?? this.reference,
      name: name ?? this.name,
      activity: activity ?? this.activity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      contractNature: contractNature ?? this.contractNature,
      billedStaff: billedStaff ?? this.billedStaff,
      paidStaff: paidStaff ?? this.paidStaff,
      status: status ?? this.status,
      statusComment: statusComment ?? this.statusComment,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (activity.present) {
      map['activity'] = Variable<String>(activity.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (contractNature.present) {
      map['contract_nature'] = Variable<String>(contractNature.value);
    }
    if (billedStaff.present) {
      map['billed_staff'] = Variable<int>(billedStaff.value);
    }
    if (paidStaff.present) {
      map['paid_staff'] = Variable<int>(paidStaff.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (statusComment.present) {
      map['status_comment'] = Variable<String>(statusComment.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillingLineRecordsCompanion(')
          ..write('localId: $localId, ')
          ..write('reference: $reference, ')
          ..write('name: $name, ')
          ..write('activity: $activity, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('contractNature: $contractNature, ')
          ..write('billedStaff: $billedStaff, ')
          ..write('paidStaff: $paidStaff, ')
          ..write('status: $status, ')
          ..write('statusComment: $statusComment, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnualBillingRecordsTable extends AnnualBillingRecords
    with TableInfo<$AnnualBillingRecordsTable, AnnualBillingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnualBillingRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lineLocalIdMeta = const VerificationMeta(
    'lineLocalId',
  );
  @override
  late final GeneratedColumn<String> lineLocalId = GeneratedColumn<String>(
    'line_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthlyRateMeta = const VerificationMeta(
    'monthlyRate',
  );
  @override
  late final GeneratedColumn<double> monthlyRate = GeneratedColumn<double>(
    'monthly_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lineLocalId,
    year,
    monthlyRate,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annual_billing_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnualBillingRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('line_local_id')) {
      context.handle(
        _lineLocalIdMeta,
        lineLocalId.isAcceptableOrUnknown(
          data['line_local_id']!,
          _lineLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lineLocalIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('monthly_rate')) {
      context.handle(
        _monthlyRateMeta,
        monthlyRate.isAcceptableOrUnknown(
          data['monthly_rate']!,
          _monthlyRateMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lineLocalId, year};
  @override
  AnnualBillingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnualBillingRecord(
      lineLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_local_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      monthlyRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_rate'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AnnualBillingRecordsTable createAlias(String alias) {
    return $AnnualBillingRecordsTable(attachedDatabase, alias);
  }
}

class AnnualBillingRecord extends DataClass
    implements Insertable<AnnualBillingRecord> {
  final String lineLocalId;
  final int year;
  final double monthlyRate;
  final DateTime updatedAt;
  const AnnualBillingRecord({
    required this.lineLocalId,
    required this.year,
    required this.monthlyRate,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['line_local_id'] = Variable<String>(lineLocalId);
    map['year'] = Variable<int>(year);
    map['monthly_rate'] = Variable<double>(monthlyRate);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AnnualBillingRecordsCompanion toCompanion(bool nullToAbsent) {
    return AnnualBillingRecordsCompanion(
      lineLocalId: Value(lineLocalId),
      year: Value(year),
      monthlyRate: Value(monthlyRate),
      updatedAt: Value(updatedAt),
    );
  }

  factory AnnualBillingRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnualBillingRecord(
      lineLocalId: serializer.fromJson<String>(json['lineLocalId']),
      year: serializer.fromJson<int>(json['year']),
      monthlyRate: serializer.fromJson<double>(json['monthlyRate']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lineLocalId': serializer.toJson<String>(lineLocalId),
      'year': serializer.toJson<int>(year),
      'monthlyRate': serializer.toJson<double>(monthlyRate),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AnnualBillingRecord copyWith({
    String? lineLocalId,
    int? year,
    double? monthlyRate,
    DateTime? updatedAt,
  }) => AnnualBillingRecord(
    lineLocalId: lineLocalId ?? this.lineLocalId,
    year: year ?? this.year,
    monthlyRate: monthlyRate ?? this.monthlyRate,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AnnualBillingRecord copyWithCompanion(AnnualBillingRecordsCompanion data) {
    return AnnualBillingRecord(
      lineLocalId: data.lineLocalId.present
          ? data.lineLocalId.value
          : this.lineLocalId,
      year: data.year.present ? data.year.value : this.year,
      monthlyRate: data.monthlyRate.present
          ? data.monthlyRate.value
          : this.monthlyRate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnualBillingRecord(')
          ..write('lineLocalId: $lineLocalId, ')
          ..write('year: $year, ')
          ..write('monthlyRate: $monthlyRate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lineLocalId, year, monthlyRate, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnualBillingRecord &&
          other.lineLocalId == this.lineLocalId &&
          other.year == this.year &&
          other.monthlyRate == this.monthlyRate &&
          other.updatedAt == this.updatedAt);
}

class AnnualBillingRecordsCompanion
    extends UpdateCompanion<AnnualBillingRecord> {
  final Value<String> lineLocalId;
  final Value<int> year;
  final Value<double> monthlyRate;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AnnualBillingRecordsCompanion({
    this.lineLocalId = const Value.absent(),
    this.year = const Value.absent(),
    this.monthlyRate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnualBillingRecordsCompanion.insert({
    required String lineLocalId,
    required int year,
    this.monthlyRate = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : lineLocalId = Value(lineLocalId),
       year = Value(year),
       updatedAt = Value(updatedAt);
  static Insertable<AnnualBillingRecord> custom({
    Expression<String>? lineLocalId,
    Expression<int>? year,
    Expression<double>? monthlyRate,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lineLocalId != null) 'line_local_id': lineLocalId,
      if (year != null) 'year': year,
      if (monthlyRate != null) 'monthly_rate': monthlyRate,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnualBillingRecordsCompanion copyWith({
    Value<String>? lineLocalId,
    Value<int>? year,
    Value<double>? monthlyRate,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AnnualBillingRecordsCompanion(
      lineLocalId: lineLocalId ?? this.lineLocalId,
      year: year ?? this.year,
      monthlyRate: monthlyRate ?? this.monthlyRate,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lineLocalId.present) {
      map['line_local_id'] = Variable<String>(lineLocalId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (monthlyRate.present) {
      map['monthly_rate'] = Variable<double>(monthlyRate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnualBillingRecordsCompanion(')
          ..write('lineLocalId: $lineLocalId, ')
          ..write('year: $year, ')
          ..write('monthlyRate: $monthlyRate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthlyPaymentRecordsTable extends MonthlyPaymentRecords
    with TableInfo<$MonthlyPaymentRecordsTable, MonthlyPaymentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyPaymentRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lineLocalIdMeta = const VerificationMeta(
    'lineLocalId',
  );
  @override
  late final GeneratedColumn<String> lineLocalId = GeneratedColumn<String>(
    'line_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthIndexMeta = const VerificationMeta(
    'monthIndex',
  );
  @override
  late final GeneratedColumn<int> monthIndex = GeneratedColumn<int>(
    'month_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lineLocalId,
    year,
    monthIndex,
    monthKey,
    amount,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_payment_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthlyPaymentRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('line_local_id')) {
      context.handle(
        _lineLocalIdMeta,
        lineLocalId.isAcceptableOrUnknown(
          data['line_local_id']!,
          _lineLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lineLocalIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month_index')) {
      context.handle(
        _monthIndexMeta,
        monthIndex.isAcceptableOrUnknown(data['month_index']!, _monthIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIndexMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lineLocalId, year, monthIndex};
  @override
  MonthlyPaymentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyPaymentRecord(
      lineLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_local_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      monthIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_index'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MonthlyPaymentRecordsTable createAlias(String alias) {
    return $MonthlyPaymentRecordsTable(attachedDatabase, alias);
  }
}

class MonthlyPaymentRecord extends DataClass
    implements Insertable<MonthlyPaymentRecord> {
  final String lineLocalId;
  final int year;
  final int monthIndex;
  final String monthKey;
  final double amount;
  final DateTime updatedAt;
  const MonthlyPaymentRecord({
    required this.lineLocalId,
    required this.year,
    required this.monthIndex,
    required this.monthKey,
    required this.amount,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['line_local_id'] = Variable<String>(lineLocalId);
    map['year'] = Variable<int>(year);
    map['month_index'] = Variable<int>(monthIndex);
    map['month_key'] = Variable<String>(monthKey);
    map['amount'] = Variable<double>(amount);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MonthlyPaymentRecordsCompanion toCompanion(bool nullToAbsent) {
    return MonthlyPaymentRecordsCompanion(
      lineLocalId: Value(lineLocalId),
      year: Value(year),
      monthIndex: Value(monthIndex),
      monthKey: Value(monthKey),
      amount: Value(amount),
      updatedAt: Value(updatedAt),
    );
  }

  factory MonthlyPaymentRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyPaymentRecord(
      lineLocalId: serializer.fromJson<String>(json['lineLocalId']),
      year: serializer.fromJson<int>(json['year']),
      monthIndex: serializer.fromJson<int>(json['monthIndex']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      amount: serializer.fromJson<double>(json['amount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lineLocalId': serializer.toJson<String>(lineLocalId),
      'year': serializer.toJson<int>(year),
      'monthIndex': serializer.toJson<int>(monthIndex),
      'monthKey': serializer.toJson<String>(monthKey),
      'amount': serializer.toJson<double>(amount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MonthlyPaymentRecord copyWith({
    String? lineLocalId,
    int? year,
    int? monthIndex,
    String? monthKey,
    double? amount,
    DateTime? updatedAt,
  }) => MonthlyPaymentRecord(
    lineLocalId: lineLocalId ?? this.lineLocalId,
    year: year ?? this.year,
    monthIndex: monthIndex ?? this.monthIndex,
    monthKey: monthKey ?? this.monthKey,
    amount: amount ?? this.amount,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MonthlyPaymentRecord copyWithCompanion(MonthlyPaymentRecordsCompanion data) {
    return MonthlyPaymentRecord(
      lineLocalId: data.lineLocalId.present
          ? data.lineLocalId.value
          : this.lineLocalId,
      year: data.year.present ? data.year.value : this.year,
      monthIndex: data.monthIndex.present
          ? data.monthIndex.value
          : this.monthIndex,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      amount: data.amount.present ? data.amount.value : this.amount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyPaymentRecord(')
          ..write('lineLocalId: $lineLocalId, ')
          ..write('year: $year, ')
          ..write('monthIndex: $monthIndex, ')
          ..write('monthKey: $monthKey, ')
          ..write('amount: $amount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(lineLocalId, year, monthIndex, monthKey, amount, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyPaymentRecord &&
          other.lineLocalId == this.lineLocalId &&
          other.year == this.year &&
          other.monthIndex == this.monthIndex &&
          other.monthKey == this.monthKey &&
          other.amount == this.amount &&
          other.updatedAt == this.updatedAt);
}

class MonthlyPaymentRecordsCompanion
    extends UpdateCompanion<MonthlyPaymentRecord> {
  final Value<String> lineLocalId;
  final Value<int> year;
  final Value<int> monthIndex;
  final Value<String> monthKey;
  final Value<double> amount;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MonthlyPaymentRecordsCompanion({
    this.lineLocalId = const Value.absent(),
    this.year = const Value.absent(),
    this.monthIndex = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.amount = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthlyPaymentRecordsCompanion.insert({
    required String lineLocalId,
    required int year,
    required int monthIndex,
    required String monthKey,
    this.amount = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : lineLocalId = Value(lineLocalId),
       year = Value(year),
       monthIndex = Value(monthIndex),
       monthKey = Value(monthKey),
       updatedAt = Value(updatedAt);
  static Insertable<MonthlyPaymentRecord> custom({
    Expression<String>? lineLocalId,
    Expression<int>? year,
    Expression<int>? monthIndex,
    Expression<String>? monthKey,
    Expression<double>? amount,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lineLocalId != null) 'line_local_id': lineLocalId,
      if (year != null) 'year': year,
      if (monthIndex != null) 'month_index': monthIndex,
      if (monthKey != null) 'month_key': monthKey,
      if (amount != null) 'amount': amount,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthlyPaymentRecordsCompanion copyWith({
    Value<String>? lineLocalId,
    Value<int>? year,
    Value<int>? monthIndex,
    Value<String>? monthKey,
    Value<double>? amount,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MonthlyPaymentRecordsCompanion(
      lineLocalId: lineLocalId ?? this.lineLocalId,
      year: year ?? this.year,
      monthIndex: monthIndex ?? this.monthIndex,
      monthKey: monthKey ?? this.monthKey,
      amount: amount ?? this.amount,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lineLocalId.present) {
      map['line_local_id'] = Variable<String>(lineLocalId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (monthIndex.present) {
      map['month_index'] = Variable<int>(monthIndex.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyPaymentRecordsCompanion(')
          ..write('lineLocalId: $lineLocalId, ')
          ..write('year: $year, ')
          ..write('monthIndex: $monthIndex, ')
          ..write('monthKey: $monthKey, ')
          ..write('amount: $amount, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxRecordsTable extends SyncOutboxRecords
    with TableInfo<$SyncOutboxRecordsTable, SyncOutboxRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('upsert'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthIndexMeta = const VerificationMeta(
    'monthIndex',
  );
  @override
  late final GeneratedColumn<int> monthIndex = GeneratedColumn<int>(
    'month_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    scope,
    field,
    operation,
    payloadJson,
    year,
    monthIndex,
    status,
    attempts,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('month_index')) {
      context.handle(
        _monthIndexMeta,
        monthIndex.isAcceptableOrUnknown(data['month_index']!, _monthIndexMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      monthIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_index'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncOutboxRecordsTable createAlias(String alias) {
    return $SyncOutboxRecordsTable(attachedDatabase, alias);
  }
}

class SyncOutboxRecord extends DataClass
    implements Insertable<SyncOutboxRecord> {
  final String id;
  final String entityType;
  final String entityId;
  final String scope;
  final String field;
  final String operation;
  final String payloadJson;
  final int? year;
  final int? monthIndex;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncOutboxRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.scope,
    required this.field,
    required this.operation,
    required this.payloadJson,
    this.year,
    this.monthIndex,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['scope'] = Variable<String>(scope);
    map['field'] = Variable<String>(field);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || monthIndex != null) {
      map['month_index'] = Variable<int>(monthIndex);
    }
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncOutboxRecordsCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxRecordsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      scope: Value(scope),
      field: Value(field),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      monthIndex: monthIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(monthIndex),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncOutboxRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxRecord(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      scope: serializer.fromJson<String>(json['scope']),
      field: serializer.fromJson<String>(json['field']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      year: serializer.fromJson<int?>(json['year']),
      monthIndex: serializer.fromJson<int?>(json['monthIndex']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'scope': serializer.toJson<String>(scope),
      'field': serializer.toJson<String>(field),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'year': serializer.toJson<int?>(year),
      'monthIndex': serializer.toJson<int?>(monthIndex),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncOutboxRecord copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? scope,
    String? field,
    String? operation,
    String? payloadJson,
    Value<int?> year = const Value.absent(),
    Value<int?> monthIndex = const Value.absent(),
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SyncOutboxRecord(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    scope: scope ?? this.scope,
    field: field ?? this.field,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    year: year.present ? year.value : this.year,
    monthIndex: monthIndex.present ? monthIndex.value : this.monthIndex,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncOutboxRecord copyWithCompanion(SyncOutboxRecordsCompanion data) {
    return SyncOutboxRecord(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      scope: data.scope.present ? data.scope.value : this.scope,
      field: data.field.present ? data.field.value : this.field,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      year: data.year.present ? data.year.value : this.year,
      monthIndex: data.monthIndex.present
          ? data.monthIndex.value
          : this.monthIndex,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRecord(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('scope: $scope, ')
          ..write('field: $field, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('year: $year, ')
          ..write('monthIndex: $monthIndex, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    scope,
    field,
    operation,
    payloadJson,
    year,
    monthIndex,
    status,
    attempts,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxRecord &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.scope == this.scope &&
          other.field == this.field &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.year == this.year &&
          other.monthIndex == this.monthIndex &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncOutboxRecordsCompanion extends UpdateCompanion<SyncOutboxRecord> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> scope;
  final Value<String> field;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<int?> year;
  final Value<int?> monthIndex;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncOutboxRecordsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.scope = const Value.absent(),
    this.field = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.year = const Value.absent(),
    this.monthIndex = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxRecordsCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String scope,
    required String field,
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.year = const Value.absent(),
    this.monthIndex = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       scope = Value(scope),
       field = Value(field),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncOutboxRecord> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? scope,
    Expression<String>? field,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<int>? year,
    Expression<int>? monthIndex,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (scope != null) 'scope': scope,
      if (field != null) 'field': field,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (year != null) 'year': year,
      if (monthIndex != null) 'month_index': monthIndex,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? scope,
    Value<String>? field,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<int?>? year,
    Value<int?>? monthIndex,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncOutboxRecordsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      scope: scope ?? this.scope,
      field: field ?? this.field,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      year: year ?? this.year,
      monthIndex: monthIndex ?? this.monthIndex,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (monthIndex.present) {
      map['month_index'] = Variable<int>(monthIndex.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRecordsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('scope: $scope, ')
          ..write('field: $field, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('year: $year, ')
          ..write('monthIndex: $monthIndex, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BillingLineRecordsTable billingLineRecords =
      $BillingLineRecordsTable(this);
  late final $AnnualBillingRecordsTable annualBillingRecords =
      $AnnualBillingRecordsTable(this);
  late final $MonthlyPaymentRecordsTable monthlyPaymentRecords =
      $MonthlyPaymentRecordsTable(this);
  late final $SyncOutboxRecordsTable syncOutboxRecords =
      $SyncOutboxRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    billingLineRecords,
    annualBillingRecords,
    monthlyPaymentRecords,
    syncOutboxRecords,
  ];
}

typedef $$BillingLineRecordsTableCreateCompanionBuilder =
    BillingLineRecordsCompanion Function({
      required String localId,
      Value<String> reference,
      Value<String> name,
      Value<String> activity,
      Value<String> startDate,
      Value<String> endDate,
      Value<String> contractNature,
      Value<int> billedStaff,
      Value<int> paidStaff,
      Value<String> status,
      Value<String> statusComment,
      Value<String> syncState,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BillingLineRecordsTableUpdateCompanionBuilder =
    BillingLineRecordsCompanion Function({
      Value<String> localId,
      Value<String> reference,
      Value<String> name,
      Value<String> activity,
      Value<String> startDate,
      Value<String> endDate,
      Value<String> contractNature,
      Value<int> billedStaff,
      Value<int> paidStaff,
      Value<String> status,
      Value<String> statusComment,
      Value<String> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BillingLineRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $BillingLineRecordsTable> {
  $$BillingLineRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contractNature => $composableBuilder(
    column: $table.contractNature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billedStaff => $composableBuilder(
    column: $table.billedStaff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidStaff => $composableBuilder(
    column: $table.paidStaff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusComment => $composableBuilder(
    column: $table.statusComment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BillingLineRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillingLineRecordsTable> {
  $$BillingLineRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contractNature => $composableBuilder(
    column: $table.contractNature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billedStaff => $composableBuilder(
    column: $table.billedStaff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidStaff => $composableBuilder(
    column: $table.paidStaff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusComment => $composableBuilder(
    column: $table.statusComment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BillingLineRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillingLineRecordsTable> {
  $$BillingLineRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get activity =>
      $composableBuilder(column: $table.activity, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get contractNature => $composableBuilder(
    column: $table.contractNature,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billedStaff => $composableBuilder(
    column: $table.billedStaff,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidStaff =>
      $composableBuilder(column: $table.paidStaff, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get statusComment => $composableBuilder(
    column: $table.statusComment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BillingLineRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillingLineRecordsTable,
          BillingLineRecord,
          $$BillingLineRecordsTableFilterComposer,
          $$BillingLineRecordsTableOrderingComposer,
          $$BillingLineRecordsTableAnnotationComposer,
          $$BillingLineRecordsTableCreateCompanionBuilder,
          $$BillingLineRecordsTableUpdateCompanionBuilder,
          (
            BillingLineRecord,
            BaseReferences<
              _$AppDatabase,
              $BillingLineRecordsTable,
              BillingLineRecord
            >,
          ),
          BillingLineRecord,
          PrefetchHooks Function()
        > {
  $$BillingLineRecordsTableTableManager(
    _$AppDatabase db,
    $BillingLineRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillingLineRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillingLineRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillingLineRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> activity = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<String> contractNature = const Value.absent(),
                Value<int> billedStaff = const Value.absent(),
                Value<int> paidStaff = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> statusComment = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillingLineRecordsCompanion(
                localId: localId,
                reference: reference,
                name: name,
                activity: activity,
                startDate: startDate,
                endDate: endDate,
                contractNature: contractNature,
                billedStaff: billedStaff,
                paidStaff: paidStaff,
                status: status,
                statusComment: statusComment,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String> reference = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> activity = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<String> contractNature = const Value.absent(),
                Value<int> billedStaff = const Value.absent(),
                Value<int> paidStaff = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> statusComment = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BillingLineRecordsCompanion.insert(
                localId: localId,
                reference: reference,
                name: name,
                activity: activity,
                startDate: startDate,
                endDate: endDate,
                contractNature: contractNature,
                billedStaff: billedStaff,
                paidStaff: paidStaff,
                status: status,
                statusComment: statusComment,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BillingLineRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillingLineRecordsTable,
      BillingLineRecord,
      $$BillingLineRecordsTableFilterComposer,
      $$BillingLineRecordsTableOrderingComposer,
      $$BillingLineRecordsTableAnnotationComposer,
      $$BillingLineRecordsTableCreateCompanionBuilder,
      $$BillingLineRecordsTableUpdateCompanionBuilder,
      (
        BillingLineRecord,
        BaseReferences<
          _$AppDatabase,
          $BillingLineRecordsTable,
          BillingLineRecord
        >,
      ),
      BillingLineRecord,
      PrefetchHooks Function()
    >;
typedef $$AnnualBillingRecordsTableCreateCompanionBuilder =
    AnnualBillingRecordsCompanion Function({
      required String lineLocalId,
      required int year,
      Value<double> monthlyRate,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AnnualBillingRecordsTableUpdateCompanionBuilder =
    AnnualBillingRecordsCompanion Function({
      Value<String> lineLocalId,
      Value<int> year,
      Value<double> monthlyRate,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AnnualBillingRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnualBillingRecordsTable> {
  $$AnnualBillingRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lineLocalId => $composableBuilder(
    column: $table.lineLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyRate => $composableBuilder(
    column: $table.monthlyRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnnualBillingRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnualBillingRecordsTable> {
  $$AnnualBillingRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lineLocalId => $composableBuilder(
    column: $table.lineLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyRate => $composableBuilder(
    column: $table.monthlyRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnnualBillingRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnualBillingRecordsTable> {
  $$AnnualBillingRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lineLocalId => $composableBuilder(
    column: $table.lineLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<double> get monthlyRate => $composableBuilder(
    column: $table.monthlyRate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AnnualBillingRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnualBillingRecordsTable,
          AnnualBillingRecord,
          $$AnnualBillingRecordsTableFilterComposer,
          $$AnnualBillingRecordsTableOrderingComposer,
          $$AnnualBillingRecordsTableAnnotationComposer,
          $$AnnualBillingRecordsTableCreateCompanionBuilder,
          $$AnnualBillingRecordsTableUpdateCompanionBuilder,
          (
            AnnualBillingRecord,
            BaseReferences<
              _$AppDatabase,
              $AnnualBillingRecordsTable,
              AnnualBillingRecord
            >,
          ),
          AnnualBillingRecord,
          PrefetchHooks Function()
        > {
  $$AnnualBillingRecordsTableTableManager(
    _$AppDatabase db,
    $AnnualBillingRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnualBillingRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnualBillingRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AnnualBillingRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> lineLocalId = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<double> monthlyRate = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnualBillingRecordsCompanion(
                lineLocalId: lineLocalId,
                year: year,
                monthlyRate: monthlyRate,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lineLocalId,
                required int year,
                Value<double> monthlyRate = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AnnualBillingRecordsCompanion.insert(
                lineLocalId: lineLocalId,
                year: year,
                monthlyRate: monthlyRate,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnnualBillingRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnualBillingRecordsTable,
      AnnualBillingRecord,
      $$AnnualBillingRecordsTableFilterComposer,
      $$AnnualBillingRecordsTableOrderingComposer,
      $$AnnualBillingRecordsTableAnnotationComposer,
      $$AnnualBillingRecordsTableCreateCompanionBuilder,
      $$AnnualBillingRecordsTableUpdateCompanionBuilder,
      (
        AnnualBillingRecord,
        BaseReferences<
          _$AppDatabase,
          $AnnualBillingRecordsTable,
          AnnualBillingRecord
        >,
      ),
      AnnualBillingRecord,
      PrefetchHooks Function()
    >;
typedef $$MonthlyPaymentRecordsTableCreateCompanionBuilder =
    MonthlyPaymentRecordsCompanion Function({
      required String lineLocalId,
      required int year,
      required int monthIndex,
      required String monthKey,
      Value<double> amount,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MonthlyPaymentRecordsTableUpdateCompanionBuilder =
    MonthlyPaymentRecordsCompanion Function({
      Value<String> lineLocalId,
      Value<int> year,
      Value<int> monthIndex,
      Value<String> monthKey,
      Value<double> amount,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MonthlyPaymentRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyPaymentRecordsTable> {
  $$MonthlyPaymentRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lineLocalId => $composableBuilder(
    column: $table.lineLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthIndex => $composableBuilder(
    column: $table.monthIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MonthlyPaymentRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyPaymentRecordsTable> {
  $$MonthlyPaymentRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lineLocalId => $composableBuilder(
    column: $table.lineLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthIndex => $composableBuilder(
    column: $table.monthIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthlyPaymentRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyPaymentRecordsTable> {
  $$MonthlyPaymentRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lineLocalId => $composableBuilder(
    column: $table.lineLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get monthIndex => $composableBuilder(
    column: $table.monthIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MonthlyPaymentRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthlyPaymentRecordsTable,
          MonthlyPaymentRecord,
          $$MonthlyPaymentRecordsTableFilterComposer,
          $$MonthlyPaymentRecordsTableOrderingComposer,
          $$MonthlyPaymentRecordsTableAnnotationComposer,
          $$MonthlyPaymentRecordsTableCreateCompanionBuilder,
          $$MonthlyPaymentRecordsTableUpdateCompanionBuilder,
          (
            MonthlyPaymentRecord,
            BaseReferences<
              _$AppDatabase,
              $MonthlyPaymentRecordsTable,
              MonthlyPaymentRecord
            >,
          ),
          MonthlyPaymentRecord,
          PrefetchHooks Function()
        > {
  $$MonthlyPaymentRecordsTableTableManager(
    _$AppDatabase db,
    $MonthlyPaymentRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyPaymentRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MonthlyPaymentRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MonthlyPaymentRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> lineLocalId = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> monthIndex = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlyPaymentRecordsCompanion(
                lineLocalId: lineLocalId,
                year: year,
                monthIndex: monthIndex,
                monthKey: monthKey,
                amount: amount,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lineLocalId,
                required int year,
                required int monthIndex,
                required String monthKey,
                Value<double> amount = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MonthlyPaymentRecordsCompanion.insert(
                lineLocalId: lineLocalId,
                year: year,
                monthIndex: monthIndex,
                monthKey: monthKey,
                amount: amount,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonthlyPaymentRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthlyPaymentRecordsTable,
      MonthlyPaymentRecord,
      $$MonthlyPaymentRecordsTableFilterComposer,
      $$MonthlyPaymentRecordsTableOrderingComposer,
      $$MonthlyPaymentRecordsTableAnnotationComposer,
      $$MonthlyPaymentRecordsTableCreateCompanionBuilder,
      $$MonthlyPaymentRecordsTableUpdateCompanionBuilder,
      (
        MonthlyPaymentRecord,
        BaseReferences<
          _$AppDatabase,
          $MonthlyPaymentRecordsTable,
          MonthlyPaymentRecord
        >,
      ),
      MonthlyPaymentRecord,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxRecordsTableCreateCompanionBuilder =
    SyncOutboxRecordsCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String scope,
      required String field,
      Value<String> operation,
      Value<String> payloadJson,
      Value<int?> year,
      Value<int?> monthIndex,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncOutboxRecordsTableUpdateCompanionBuilder =
    SyncOutboxRecordsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> scope,
      Value<String> field,
      Value<String> operation,
      Value<String> payloadJson,
      Value<int?> year,
      Value<int?> monthIndex,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncOutboxRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxRecordsTable> {
  $$SyncOutboxRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthIndex => $composableBuilder(
    column: $table.monthIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxRecordsTable> {
  $$SyncOutboxRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthIndex => $composableBuilder(
    column: $table.monthIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxRecordsTable> {
  $$SyncOutboxRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get monthIndex => $composableBuilder(
    column: $table.monthIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncOutboxRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxRecordsTable,
          SyncOutboxRecord,
          $$SyncOutboxRecordsTableFilterComposer,
          $$SyncOutboxRecordsTableOrderingComposer,
          $$SyncOutboxRecordsTableAnnotationComposer,
          $$SyncOutboxRecordsTableCreateCompanionBuilder,
          $$SyncOutboxRecordsTableUpdateCompanionBuilder,
          (
            SyncOutboxRecord,
            BaseReferences<
              _$AppDatabase,
              $SyncOutboxRecordsTable,
              SyncOutboxRecord
            >,
          ),
          SyncOutboxRecord,
          PrefetchHooks Function()
        > {
  $$SyncOutboxRecordsTableTableManager(
    _$AppDatabase db,
    $SyncOutboxRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int?> monthIndex = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxRecordsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                scope: scope,
                field: field,
                operation: operation,
                payloadJson: payloadJson,
                year: year,
                monthIndex: monthIndex,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String scope,
                required String field,
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int?> monthIndex = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxRecordsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                scope: scope,
                field: field,
                operation: operation,
                payloadJson: payloadJson,
                year: year,
                monthIndex: monthIndex,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxRecordsTable,
      SyncOutboxRecord,
      $$SyncOutboxRecordsTableFilterComposer,
      $$SyncOutboxRecordsTableOrderingComposer,
      $$SyncOutboxRecordsTableAnnotationComposer,
      $$SyncOutboxRecordsTableCreateCompanionBuilder,
      $$SyncOutboxRecordsTableUpdateCompanionBuilder,
      (
        SyncOutboxRecord,
        BaseReferences<
          _$AppDatabase,
          $SyncOutboxRecordsTable,
          SyncOutboxRecord
        >,
      ),
      SyncOutboxRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BillingLineRecordsTableTableManager get billingLineRecords =>
      $$BillingLineRecordsTableTableManager(_db, _db.billingLineRecords);
  $$AnnualBillingRecordsTableTableManager get annualBillingRecords =>
      $$AnnualBillingRecordsTableTableManager(_db, _db.annualBillingRecords);
  $$MonthlyPaymentRecordsTableTableManager get monthlyPaymentRecords =>
      $$MonthlyPaymentRecordsTableTableManager(_db, _db.monthlyPaymentRecords);
  $$SyncOutboxRecordsTableTableManager get syncOutboxRecords =>
      $$SyncOutboxRecordsTableTableManager(_db, _db.syncOutboxRecords);
}
