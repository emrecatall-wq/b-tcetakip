import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';
import 'expense_parser.dart';

/// Ana isolate ve arka plan isolate'ları aynı Isar örneğini açabilsin diye
/// tek bir erişim noktası.
class DbService {
  static Future<Isar> open() async {
    final existing = Isar.getInstance();
    if (existing != null) return existing;
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open([ExpenseSchema], directory: dir.path);
  }

  /// Aynı işlem hem SMS hem bildirim olarak gelebilir; 3 dk içinde aynı tutar +
  /// aynı banka varsa tekrar kaydetme.
  static Future<bool> saveParsed(
    ParsedExpense p, {
    required String sourceType,
    required String raw,
  }) async {
    final isar = await open();
    final from = p.date.subtract(const Duration(minutes: 3));
    final to = p.date.add(const Duration(minutes: 3));
    final dup = await isar.expenses
        .filter()
        .dateBetween(from, to)
        .amountBetween(p.amount - 0.001, p.amount + 0.001)
        .findFirst();
    if (dup != null) return false;

    final e = Expense()
      ..bankName = p.bankName
      ..amount = p.amount
      ..merchant = p.merchant
      ..date = p.date
      ..category = p.category
      ..sourceType = sourceType
      ..rawMessage = raw;
    await isar.writeTxn(() => isar.expenses.put(e));
    return true;
  }

  static Future<void> add(Expense e) async {
    final isar = await open();
    await isar.writeTxn(() => isar.expenses.put(e));
  }

  static Future<void> delete(int id) async {
    final isar = await open();
    await isar.writeTxn(() => isar.expenses.delete(id));
  }
}
