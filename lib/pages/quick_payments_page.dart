import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/billing_line.dart';
import '../models/billing_years.dart';
import '../sync/pending_change.dart';
import '../utils/billing_reference.dart';
import '../widgets/brand_logo.dart';

class QuickPaymentsPage extends StatefulWidget {
  const QuickPaymentsPage({
    super.key,
    required this.lines,
    required this.selectedYear,
    required this.onYearChanged,
    required this.onLinesChanged,
    required this.onPendingChanges,
    required this.onOpenExport,
  });

  final List<BillingLine> lines;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<List<BillingLine>> onLinesChanged;
  final ValueChanged<List<PendingChange>> onPendingChanges;
  final VoidCallback onOpenExport;

  @override
  State<QuickPaymentsPage> createState() => _QuickPaymentsPageState();
}

class _QuickPaymentsPageState extends State<QuickPaymentsPage> {
  late List<BillingLine> _lines;
  late int _year;
  String _query = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _lines = List.of(widget.lines);
    _year = widget.selectedYear;
  }

  @override
  void didUpdateWidget(covariant QuickPaymentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.lines, widget.lines)) {
      _lines = List.of(widget.lines);
    }
    if (oldWidget.selectedYear != widget.selectedYear) {
      _year = widget.selectedYear;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _query = value);
    });
  }

  List<BillingLine> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _lines;
    return _lines.where((line) {
      return line.odooId.toLowerCase().contains(q) ||
          line.appellationComptable.toLowerCase().contains(q) ||
          line.name.toLowerCase().contains(q) ||
          line.reference.toLowerCase().contains(q);
    }).toList();
  }

  void _replaceLine(BillingLine oldLine, BillingLine newLine, {String? month}) {
    final next = List<BillingLine>.of(_lines);
    final index = next.indexWhere((line) => line.id == oldLine.id);
    if (index < 0) return;
    next[index] = newLine.copyWith(syncState: SyncState.dirty);
    setState(() => _lines = next);
    widget.onLinesChanged(next);
    final annual = newLine.annualBilling(_year);
    final now = DateTime.now();
    final changes = <PendingChange>[
      PendingChange(
        id: '${now.microsecondsSinceEpoch}_quick_annual',
        lineId: newLine.id,
        reference: newLine.reference,
        scope: ChangeScope.annualBilling,
        field: '__annualSnapshot',
        value: annual.toJson(),
        year: _year,
        createdAt: now,
      ),
    ];
    if (month != null) {
      changes.add(
        PendingChange(
          id: '${now.microsecondsSinceEpoch}_quick_$month',
          lineId: newLine.id,
          reference: newLine.reference,
          scope: ChangeScope.paymentCell,
          field: month,
          value: annual.payments[month] ?? 0,
          year: _year,
          createdAt: now,
        ),
      );
    }
    widget.onPendingChanges(changes);
  }

  Future<void> _showPaymentDialog() async {
    final result = await showDialog<_PaymentDialogResult>(
      context: context,
      builder: (context) => _PaymentDialog(
        lines: _lines,
        year: _year,
        clientLabel: _clientLabel,
        parseAmount: _parseAmount,
      ),
    );
    if (result == null || !result.saved || result.client == null) return;
    final selectedMonth = result.month;
    final selected = result.client!;
    final annual = selected.annualBilling(_year);
    final payments = Map<String, double>.of(annual.payments)
      ..[selectedMonth] = result.amount;
    _replaceLine(
      selected,
      selected.withAnnualBilling(_year, annual.copyWith(payments: payments)),
      month: selectedMonth,
    );
  }

  Future<void> _showNewClientDialog() async {
    final values = await showDialog<_NewClientValues>(
      context: context,
      builder: (context) => const _NewClientDialog(),
    );
    if (values == null) return;
    final line = BillingLine(
      odooId: values.matricule,
      appellationComptable: values.client,
      reference: '',
      name: values.site,
      activity: 'GARDIENNAGE',
      startDate: '',
      endDate: '',
      contractNature: '',
      billedStaff: values.day + values.night,
      paidStaff: 0,
      contractAmount: values.contract,
      weaponCount: values.weapons,
      dayStaff: values.day,
      nightStaff: values.night,
      annualBillings: {_year: AnnualBillingData.empty()},
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.dirty,
    );
    final preparedLine = line.copyWith(
      reference: nextBillingReference(line.odooId, _lines),
    );
    setState(() => _lines = [preparedLine, ..._lines]);
    widget.onLinesChanged(_lines);
    final now = DateTime.now();
    widget.onPendingChanges([
      PendingChange(
        id: '${now.microsecondsSinceEpoch}_new_line',
        lineId: preparedLine.id,
        reference: preparedLine.reference,
        scope: ChangeScope.line,
        field: '__lineSnapshot',
        value: preparedLine.toJson(),
        createdAt: now,
      ),
      PendingChange(
        id: '${now.microsecondsSinceEpoch}_new_annual',
        lineId: preparedLine.id,
        reference: preparedLine.reference,
        scope: ChangeScope.annualBilling,
        field: '__annualSnapshot',
        value: preparedLine.annualBilling(_year).toJson(),
        year: _year,
        createdAt: now,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final lines = _filtered;
    final factTotal = lines.fold<int>(0, (sum, line) => sum + line.billedStaff);
    final paidTotal = lines.fold<int>(0, (sum, line) => sum + line.paidStaff);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = const Text(
                'Paiements clients',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              );
              final year = DropdownButton<int>(
                value: _year,
                items: [
                  for (final year in billingYearOptions())
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (year) {
                  if (year != null) {
                    setState(() => _year = year);
                    widget.onYearChanged(year);
                  }
                },
              );
              final export = OutlinedButton.icon(
                onPressed: widget.onOpenExport,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Rapport / export'),
              );
              if (constraints.maxWidth < 900) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [title, year, export],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Paiements clients',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  year,
                  const SizedBox(width: 8),
                  export,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                onChanged: _handleSearchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher rapidement un client...',
                ),
              );
              final payment = FilledButton.icon(
                onPressed: _showPaymentDialog,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Ajouter un paiement'),
              );
              final newClient = OutlinedButton.icon(
                onPressed: _showNewClientDialog,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Nouveau client'),
              );
              if (constraints.maxWidth < 900) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(width: constraints.maxWidth, child: search),
                    payment,
                    newClient,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 10),
                  payment,
                  const SizedBox(width: 8),
                  newClient,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: _PaymentsGrid(
                lines: lines,
                year: _year,
                billedStaffTotal: factTotal,
                paidStaffTotal: paidTotal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDialogResult {
  const _PaymentDialogResult({
    required this.client,
    required this.month,
    required this.amount,
  });

  final BillingLine? client;
  final String month;
  final double amount;

  bool get saved => client != null && amount > 0;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.lines,
    required this.year,
    required this.clientLabel,
    required this.parseAmount,
  });

  final List<BillingLine> lines;
  final int year;
  final String Function(BillingLine) clientLabel;
  final double Function(String) parseAmount;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  BillingLine? _selected;
  String _month = months.first;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selected != null && widget.parseAmount(_amountController.text) > 0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              icon: Icons.payments_outlined,
              eyebrow: 'ENCAISSEMENT CLIENT',
              title: 'Ajouter un paiement',
              subtitle: 'Enregistrez le règlement sur le mois concerné.',
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DialogSectionTitle(
                      icon: Icons.person_search_outlined,
                      title: '1. Sélectionner le client',
                    ),
                    const SizedBox(height: 10),
                    Autocomplete<BillingLine>(
                      displayStringForOption: widget.clientLabel,
                      optionsBuilder: (value) {
                        final q = value.text.trim().toLowerCase();
                        if (q.isEmpty) {
                          return const Iterable<BillingLine>.empty();
                        }
                        return widget.lines
                            .where((line) {
                              final searchable =
                                  '${widget.clientLabel(line)} ${line.name} ${line.reference}'
                                      .toLowerCase();
                              return searchable.contains(q);
                            })
                            .take(30);
                      },
                      onSelected: (line) => setState(() => _selected = line),
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: (_) {
                                if (_selected != null) {
                                  setState(() => _selected = null);
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Rechercher un client',
                                hintText:
                                    'Matricule, appellation, site ou référence',
                                prefixIcon: Icon(Icons.search),
                              ),
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: Colors.white,
                            elevation: 12,
                            shadowColor: const Color(0x33101F33),
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 280,
                                maxWidth: 580,
                              ),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1, indent: 58),
                                itemBuilder: (context, index) {
                                  final line = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 17,
                                      backgroundColor: const Color(0xFFEFF6FF),
                                      child: Text(
                                        (line.appellationComptable.isEmpty
                                                ? line.name
                                                : line.appellationComptable)
                                            .trim()
                                            .characters
                                            .take(1)
                                            .toString()
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      line.appellationComptable.isEmpty
                                          ? line.name
                                          : line.appellationComptable,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${line.odooId} · ${line.name.isEmpty ? 'Sans site' : line.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => onSelected(line),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: _selected == null
                          ? const SizedBox(height: 8)
                          : Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _SelectedClientCard(
                                line: _selected!,
                                label: widget.clientLabel(_selected!),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    const _DialogSectionTitle(
                      icon: Icons.calendar_month_outlined,
                      title: '2. Définir le règlement',
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fields = [
                          DropdownButtonFormField<String>(
                            initialValue: _month,
                            decoration: const InputDecoration(
                              labelText: 'Mois concerné',
                              prefixIcon: Icon(Icons.event_outlined),
                            ),
                            items: [
                              for (final item in months)
                                DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _month = value);
                            },
                          ),
                          TextField(
                            controller: _amountController,
                            onChanged: (_) => setState(() {}),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Montant payé',
                              hintText: '0',
                              prefixIcon: Icon(Icons.payments_outlined),
                              suffixText: 'FCFA',
                            ),
                          ),
                        ];
                        if (constraints.maxWidth < 500) {
                          return Column(
                            children: [
                              fields[0],
                              const SizedBox(height: 12),
                              fields[1],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: fields[0]),
                            const SizedBox(width: 12),
                            Expanded(child: fields[1]),
                          ],
                        );
                      },
                    ),
                    if (_selected != null) ...[
                      const SizedBox(height: 16),
                      _PaymentPreview(
                        client: widget.clientLabel(_selected!),
                        month: _month,
                        amount: widget.parseAmount(_amountController.text),
                      ),
                    ],
                    SizedBox(height: media.width < 600 ? 8 : 16),
                  ],
                ),
              ),
            ),
            _DialogFooter(
              cancelLabel: 'Annuler',
              confirmLabel: 'Enregistrer le paiement',
              confirmIcon: Icons.check_rounded,
              enabled: _canSubmit,
              onCancel: () => Navigator.pop(context),
              onConfirm: () => Navigator.pop(
                context,
                _PaymentDialogResult(
                  client: _selected,
                  month: _month,
                  amount: widget.parseAmount(_amountController.text),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewClientValues {
  const _NewClientValues({
    required this.matricule,
    required this.client,
    required this.site,
    required this.contract,
    required this.weapons,
    required this.day,
    required this.night,
  });

  final String matricule;
  final String client;
  final String site;
  final double contract;
  final int weapons;
  final int day;
  final int night;
}

class _NewClientDialog extends StatefulWidget {
  const _NewClientDialog();

  @override
  State<_NewClientDialog> createState() => _NewClientDialogState();
}

class _NewClientDialogState extends State<_NewClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _matricule;
  late final TextEditingController _client;
  late final TextEditingController _site;
  late final TextEditingController _contract;
  late final TextEditingController _weapons;
  late final TextEditingController _day;
  late final TextEditingController _night;

  @override
  void initState() {
    super.initState();
    _matricule = TextEditingController();
    _client = TextEditingController();
    _site = TextEditingController();
    _contract = TextEditingController();
    _weapons = TextEditingController(text: '0');
    _day = TextEditingController(text: '0');
    _night = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    for (final controller in [
      _matricule,
      _client,
      _site,
      _contract,
      _weapons,
      _day,
      _night,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label est requis';
    return null;
  }

  int _int(String value) => int.tryParse(value.trim()) ?? 0;
  double _double(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DialogHeader(
              icon: Icons.person_add_alt_1_outlined,
              eyebrow: 'RÉFÉRENTIEL CLIENTS',
              title: 'Créer un nouveau client',
              subtitle:
                  'Ajoutez les informations nécessaires à la facturation.',
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _DialogSectionTitle(
                        icon: Icons.badge_outlined,
                        title: '1. Identification',
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fields = [
                            TextFormField(
                              controller: _matricule,
                              validator: (value) =>
                                  _required(value, 'Le matricule'),
                              decoration: const InputDecoration(
                                labelText: 'Matricule / ID Odoo *',
                                hintText: 'Ex. CLT-0042',
                                prefixIcon: Icon(Icons.tag_outlined),
                              ),
                            ),
                            TextFormField(
                              controller: _client,
                              validator: (value) =>
                                  _required(value, 'L’appellation comptable'),
                              decoration: const InputDecoration(
                                labelText: 'Client / appellation comptable *',
                                hintText: 'Nom utilisé sur les factures',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                            ),
                          ];
                          if (constraints.maxWidth < 520) {
                            return Column(
                              children: [
                                fields[0],
                                const SizedBox(height: 12),
                                fields[1],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: fields[0]),
                              const SizedBox(width: 12),
                              Expanded(child: fields[1]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _site,
                        decoration: const InputDecoration(
                          labelText: 'Site / nom court',
                          hintText: 'Ex. Siège social, chantier, agence…',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _DialogSectionTitle(
                        icon: Icons.description_outlined,
                        title: '2. Données du contrat',
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _contract,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le montant du contrat est requis';
                          }
                          if (_double(value) <= 0) {
                            return 'Entrez un montant valide';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Montant du contrat *',
                          hintText: '0',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          suffixText: 'FCFA',
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _DialogSectionTitle(
                        icon: Icons.groups_outlined,
                        title: '3. Effectif et armement',
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fields = [
                            _NumberField(
                              controller: _weapons,
                              label: 'Nombre d’armes',
                              icon: Icons.shield_outlined,
                            ),
                            _NumberField(
                              controller: _day,
                              label: 'Agents de jour',
                              icon: Icons.wb_sunny_outlined,
                            ),
                            _NumberField(
                              controller: _night,
                              label: 'Agents de nuit',
                              icon: Icons.nightlight_outlined,
                            ),
                          ];
                          if (constraints.maxWidth < 520) {
                            return Column(
                              children: [
                                fields[0],
                                const SizedBox(height: 12),
                                fields[1],
                                const SizedBox(height: 12),
                                fields[2],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              for (
                                var index = 0;
                                index < fields.length;
                                index++
                              ) ...[
                                Expanded(child: fields[index]),
                                if (index < fields.length - 1)
                                  const SizedBox(width: 12),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            _DialogFooter(
              cancelLabel: 'Annuler',
              confirmLabel: 'Créer le client',
              confirmIcon: Icons.person_add_alt_1,
              onCancel: () => Navigator.pop(context),
              onConfirm: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(
                  context,
                  _NewClientValues(
                    matricule: _matricule.text.trim(),
                    client: _client.text.trim(),
                    site: _site.text.trim(),
                    contract: _double(_contract.text),
                    weapons: _int(_weapons.text),
                    day: _int(_day.text),
                    night: _int(_night.text),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE5F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const BrandLogo(height: 42),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: const Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _DialogSectionTitle extends StatelessWidget {
  const _DialogSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmIcon,
    required this.onCancel,
    required this.onConfirm,
    this.enabled = true,
  });

  final String cancelLabel;
  final String confirmLabel;
  final IconData confirmIcon;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          TextButton(onPressed: onCancel, child: Text(cancelLabel)),
          FilledButton.icon(
            onPressed: enabled ? onConfirm : null,
            icon: Icon(confirmIcon, size: 18),
            label: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _SelectedClientCard extends StatelessWidget {
  const _SelectedClientCard({required this.line, required this.label});

  final BillingLine line;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(Icons.check_rounded, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${line.odooId} · ${line.name.isEmpty ? 'Site non renseigné' : line.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_outlined,
            color: Color(0xFF2563EB),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PaymentPreview extends StatelessWidget {
  const _PaymentPreview({
    required this.client,
    required this.month,
    required this.amount,
  });

  final String client;
  final String month;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final amountLabel = amount > 0
        ? '${amount.toStringAsFixed(0)} FCFA'
        : 'Montant à renseigner';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Aperçu',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          Text(
            client,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(month, style: const TextStyle(color: Color(0xFF475569))),
          Text(
            amountLabel,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _PaymentsGrid extends StatefulWidget {
  const _PaymentsGrid({
    required this.lines,
    required this.year,
    required this.billedStaffTotal,
    required this.paidStaffTotal,
  });

  final List<BillingLine> lines;
  final int year;
  final int billedStaffTotal;
  final int paidStaffTotal;

  @override
  State<_PaymentsGrid> createState() => _PaymentsGridState();
}

class _PaymentsGridState extends State<_PaymentsGrid> {
  static const _rowHeight = 46.0;
  static const _headerHeight = 48.0;
  static const _columnWidths = <double>[
    140,
    260,
    150,
    90,
    110,
    110,
    90,
    90,
    110,
    110,
    110,
    110,
    110,
    110,
    110,
    110,
    110,
    110,
    110,
    110,
  ];

  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();
  final _focusNode = FocusNode(debugLabel: 'payments-grid');
  var _selectedRow = 0;
  var _selectedColumn = 0;

  double get _gridWidth => _columnWidths.fold(0, (sum, width) => sum + width);

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(rowDelta: 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(rowDelta: -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _moveSelection(columnDelta: 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveSelection(columnDelta: -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _moveSelection(rowDelta: 8);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _moveSelection(rowDelta: -8);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveSelection({int rowDelta = 0, int columnDelta = 0}) {
    final maxRow = widget.lines.length;
    final maxColumn = _columnWidths.length - 1;
    setState(() {
      _selectedRow = (_selectedRow + rowDelta).clamp(0, maxRow);
      _selectedColumn = (_selectedColumn + columnDelta).clamp(0, maxColumn);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureSelectionVisible();
    });
  }

  void _ensureSelectionVisible() {
    if (_verticalController.hasClients) {
      final top = _selectedRow * _rowHeight;
      final bottom = top + _rowHeight;
      final viewTop = _verticalController.offset;
      final viewBottom =
          viewTop + _verticalController.position.viewportDimension;
      if (top < viewTop) {
        _verticalController.animateTo(
          top,
          duration: const Duration(milliseconds: 90),
          curve: Curves.linear,
        );
      } else if (bottom > viewBottom) {
        _verticalController.animateTo(
          bottom - _verticalController.position.viewportDimension,
          duration: const Duration(milliseconds: 90),
          curve: Curves.linear,
        );
      }
    }
    if (_horizontalController.hasClients) {
      final left = _columnWidths
          .take(_selectedColumn)
          .fold<double>(0, (sum, width) => sum + width);
      final right = left + _columnWidths[_selectedColumn];
      final viewLeft = _horizontalController.offset;
      final viewRight =
          viewLeft + _horizontalController.position.viewportDimension;
      if (left < viewLeft) {
        _horizontalController.animateTo(
          left,
          duration: const Duration(milliseconds: 90),
          curve: Curves.linear,
        );
      } else if (right > viewRight) {
        _horizontalController.animateTo(
          right - _horizontalController.position.viewportDimension,
          duration: const Duration(milliseconds: 90),
          curve: Curves.linear,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPayments = {
      for (final month in months)
        month: widget.lines.fold<double>(
          0,
          (sum, line) =>
              sum + (line.annualBilling(widget.year).payments[month] ?? 0),
        ),
    };

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusNode.requestFocus,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _gridWidth,
              child: Column(
                children: [
                  _GridRow(
                    height: _headerHeight,
                    widths: _columnWidths,
                    cells: _headerCells(),
                    header: true,
                    selectedColumn: _selectedColumn,
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: _verticalController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _verticalController,
                        itemCount: widget.lines.length + 1,
                        itemExtent: _rowHeight,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemBuilder: (context, index) {
                          if (index == widget.lines.length) {
                            return _GridRow(
                              height: _rowHeight,
                              widths: _columnWidths,
                              cells: _totalCells(totalPayments),
                              total: true,
                              selected: index == _selectedRow,
                              selectedColumn: _selectedColumn,
                            );
                          }
                          return _GridRow(
                            height: _rowHeight,
                            widths: _columnWidths,
                            cells: _lineCells(widget.lines[index]),
                            striped: index.isOdd,
                            selected: index == _selectedRow,
                            selectedColumn: _selectedColumn,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _headerCells() => [
    'Matricule',
    'Client',
    'Montant contrat',
    'Nb armes',
    'Agents jour',
    'Agents nuit',
    'Eff fact',
    'Eff payé',
    ...months,
  ];

  List<String> _lineCells(BillingLine line) {
    final annual = line.annualBilling(widget.year);
    return [
      line.odooId,
      line.appellationComptable.isEmpty ? line.name : line.appellationComptable,
      _money(line.contractAmount),
      '${line.weaponCount}',
      '${line.dayStaff}',
      '${line.nightStaff}',
      '${line.billedStaff}',
      '${line.paidStaff}',
      ...[for (final month in months) _money(annual.payments[month] ?? 0)],
    ];
  }

  List<String> _totalCells(Map<String, double> totalPayments) => [
    'TOTAL',
    '',
    '',
    '',
    '',
    '',
    '${widget.billedStaffTotal}',
    '${widget.paidStaffTotal}',
    ...[for (final month in months) _money(totalPayments[month] ?? 0)],
  ];
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.height,
    required this.widths,
    required this.cells,
    this.header = false,
    this.total = false,
    this.striped = false,
    this.selected = false,
    this.selectedColumn = 0,
  });

  final double height;
  final List<double> widths;
  final List<String> cells;
  final bool header;
  final bool total;
  final bool striped;
  final bool selected;
  final int selectedColumn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var index = 0; index < cells.length; index++)
            Container(
              width: widths[index],
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: index == 0 || index == 1
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              decoration: BoxDecoration(
                color: header
                    ? const Color(0xFFE8EEF7)
                    : selected && index == selectedColumn
                    ? const Color(0xFFD8EAFE)
                    : total
                    ? const Color(0xFFDCE7F5)
                    : striped
                    ? const Color(0xFFF8FAFC)
                    : Colors.white,
                border: const Border(
                  right: BorderSide(color: Color(0xFFD7DFEA)),
                  bottom: BorderSide(color: Color(0xFFD7DFEA)),
                ),
              ),
              child: Text(
                cells[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: header ? 12 : 12,
                  fontWeight: header || total
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _clientLabel(BillingLine line) =>
    '${line.odooId} · ${line.appellationComptable.isEmpty ? line.name : line.appellationComptable}';

double _parseAmount(String value) =>
    double.tryParse(value.trim().replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
String _money(double value) => '${value.round()} FCFA';
