import 'package:butce_takip/services/expense_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Enpara bildirimi', () {
    final p = ExpenseParser.parse(
      '1.250,75 TL tutarındaki harcamanız gerçekleşmiştir. İşyeri: MIGROS ATASEHIR',
      source: 'finansbank.enpara',
    );
    expect(p, isNotNull);
    expect(p!.amount, 1250.75);
    expect(p.bankName, 'Enpara');
    expect(p.merchant, 'MIGROS ATASEHIR');
    expect(p.category, 'Market');
  });

  test('Garanti SMS', () {
    final p = ExpenseParser.parse(
      'Garanti BBVA 1234 sonlu kartinizla 03/10/2026 14:22 tarihinde OPET ESENYURT isyerinde 450,00 TL harcama yapildi.',
      source: 'GARANTI',
    );
    expect(p, isNotNull);
    expect(p!.amount, 450.0);
    expect(p.bankName, 'Garanti BBVA');
    expect(p.date.day, 3);
  });

  test('OTP mesajı yok sayılır', () {
    expect(ExpenseParser.parse('Doğrulama kodunuz 123456. 100,00 TL işlem için', source: 'AKBANK'), isNull);
  });
}
