import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _customBank = TextEditingController();
  String _bank = 'Enpara';
  String _category = 'Genel';
  DateTime _date = DateTime.now();

  static const banks = ['Enpara', 'Garanti BBVA', 'Akbank', 'İş Bankası', 'Yapı Kredi', 'Nakit', 'Diğer'];
  static const categories = [
    'Genel', 'Market', 'Akaryakıt', 'Yeme-İçme', 'Giyim', 'Online', 'Fatura', 'Ulaşım', 'Sağlık', 'Yapı-Tadilat',
  ];

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _customBank.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    setState(() => _date = DateTime(d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final amount = double.parse(_amount.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    final bankName = (_bank == 'Diğer' && _customBank.text.trim().isNotEmpty) ? _customBank.text.trim() : _bank;
    final e = Expense()
      ..bankName = bankName
      ..amount = amount
      ..merchant = _merchant.text.trim().isEmpty ? 'Elle girildi' : _merchant.text.trim()
      ..date = _date
      ..category = _category
      ..sourceType = 'MANUAL'
      ..rawMessage = '';
    Navigator.of(context).pop(e);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Harcama ekle', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Tutar (TL)', border: OutlineInputBorder()),
                validator: (v) {
                  final t = (v ?? '').trim().replaceAll('.', '').replaceAll(',', '.');
                  final n = double.tryParse(t);
                  return (n == null || n <= 0) ? 'Geçerli bir tutar gir' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _merchant,
                decoration: const InputDecoration(labelText: 'İş yeri / Firma', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _bank,
                decoration: const InputDecoration(labelText: 'Banka', border: OutlineInputBorder()),
                items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _bank = v ?? _bank),
              ),
              if (_bank == 'Diğer') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customBank,
                  decoration: const InputDecoration(labelText: 'Banka adı', border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded),
                label: Text(DateFormat('d MMMM yyyy HH:mm', 'tr_TR').format(_date)),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Padding(padding: EdgeInsets.all(12), child: Text('Kaydet'))),
            ],
          ),
        ),
      ),
    );
  }
}
