import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../models/expense.dart';
import '../services/db_service.dart';
import '../widgets/add_expense_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Isar? _isar;
  StreamSubscription<void>? _sub;
  List<Expense> _items = [];
  bool _thisMonthOnly = true;

  final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  final _dateFmt = DateFormat('d MMM yyyy, HH:mm', 'tr_TR');

  static const _palette = [
    Color(0xFF1B7F5C), Color(0xFF2E6FD8), Color(0xFFE08A1E), Color(0xFFC2415A),
    Color(0xFF7A55C9), Color(0xFF16A3B8), Color(0xFF8C8C3A), Color(0xFF6B7280),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final isar = await DbService.open();
    _isar = isar;
    await _load();
    // Arka plan isolate'ı kayıt eklediğinde otomatik yenile.
    _sub = isar.expenses.watchLazy().listen((_) => _load());
  }

  Future<void> _load() async {
    final isar = _isar;
    if (isar == null) return;
    final list = await isar.expenses.where().sortByDateDesc().findAll();
    if (mounted) setState(() => _items = list);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Expense> get _visible {
    if (!_thisMonthOnly) return _items;
    final now = DateTime.now();
    return _items.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
  }

  Future<void> _add() async {
    final e = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddExpenseSheet(),
    );
    if (e != null) await DbService.add(e);
  }

  Future<void> _confirmDelete(Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Harcama silinsin mi?'),
        content: Text('${e.merchant} • ${_money.format(e.amount)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok == true) await DbService.delete(e.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final total = items.fold<double>(0, (s, e) => s + e.amount);
    final byBank = <String, double>{};
    for (final e in items) {
      byBank[e.bankName] = (byBank[e.bankName] ?? 0) + e.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bütçe Takip'),
        actions: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Bu ay')),
              ButtonSegment(value: false, label: Text('Tümü')),
            ],
            selected: {_thisMonthOnly},
            onSelectionChanged: (s) => setState(() => _thisMonthOnly = s.first),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Harcama'),
      ),
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 720;
        final summary = _SummaryColumn(
          total: total,
          count: items.length,
          byBank: byBank,
          money: _money,
          palette: _palette,
        );
        final list = _ExpenseList(
          items: items,
          money: _money,
          dateFmt: _dateFmt,
          onLongPress: _confirmDelete,
          shrink: !wide,
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: c.maxWidth * 0.42, child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: summary)),
              Expanded(child: list),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [Padding(padding: const EdgeInsets.all(16), child: summary), list],
        );
      }),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final double total;
  final int count;
  final Map<String, double> byBank;
  final NumberFormat money;
  final List<Color> palette;

  const _SummaryColumn({
    required this.total,
    required this.count,
    required this.byBank,
    required this.money,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = byBank.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toplam harcama', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(money.format(total),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$count işlem'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Banka dağılımı', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Henüz harcama yok')))
                else ...[
                  SizedBox(
                    height: 200,
                    child: PieChart(PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 42,
                      sections: [
                        for (var i = 0; i < entries.length; i++)
                          PieChartSectionData(
                            value: entries[i].value,
                            color: palette[i % palette.length],
                            title: '${(entries[i].value / total * 100).round()}%',
                            radius: 58,
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                      ],
                    )),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < entries.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: palette[i % palette.length], shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(entries[i].key)),
                        Text(money.format(entries[i].value)),
                      ]),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpenseList extends StatelessWidget {
  final List<Expense> items;
  final NumberFormat money;
  final DateFormat dateFmt;
  final void Function(Expense) onLongPress;
  final bool shrink;

  const _ExpenseList({
    required this.items,
    required this.money,
    required this.dateFmt,
    required this.onLongPress,
    required this.shrink,
  });

  IconData _icon(Expense e) {
    switch (e.sourceType) {
      case 'SMS':
        return Icons.sms_rounded;
      case 'NOTIFICATION':
        return Icons.notifications_rounded;
      default:
        return Icons.edit_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Harcamalar SMS/bildirim geldikçe burada görünecek.')),
      );
    }
    return ListView.separated(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.fromLTRB(16, shrink ? 0 : 16, 16, 90),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final e = items[i];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onLongPress: () => onLongPress(e),
            leading: CircleAvatar(child: Icon(_icon(e), size: 20)),
            title: Text(e.merchant, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${e.bankName} • ${e.category}\n${dateFmt.format(e.date)}'),
            isThreeLine: true,
            trailing: Text(money.format(e.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
