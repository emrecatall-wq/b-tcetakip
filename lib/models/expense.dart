import 'package:isar/isar.dart';

part 'expense.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement;

  /// Örn: "Garanti BBVA", "Akbank", "İş Bankası", "Enpara", "Diğer"
  late String bankName;

  late double amount;

  /// İş yeri / firma
  late String merchant;

  @Index()
  late DateTime date;

  String category = 'Genel';

  /// "SMS", "NOTIFICATION" veya "MANUAL"
  late String sourceType;

  /// Gelen SMS/bildirimin ham metni
  String rawMessage = '';
}
