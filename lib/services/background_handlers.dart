import 'package:flutter/widgets.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:telephony/telephony.dart';

import 'db_service.dart';
import 'expense_parser.dart';

/// Uygulama kapalıyken gelen SMS. Top-level ve entry-point olmak zorunda.
@pragma('vm:entry-point')
Future<void> smsBackgroundHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await handleIncomingSms(message);
}

Future<void> handleIncomingSms(SmsMessage message) async {
  final body = message.body ?? '';
  final sender = message.address ?? '';
  final date = message.date != null
      ? DateTime.fromMillisecondsSinceEpoch(message.date!)
      : DateTime.now();
  // Metindeki tarih yoksa SMS'in geliş zamanı kullanılır.
  final parsed = ExpenseParser.parse(body, source: sender, fallbackDate: date);
  if (parsed == null) return;
  await DbService.saveParsed(parsed, sourceType: 'SMS', raw: body);
}

/// Bildirim dinleme servisinin arka plan callback'i.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationEvent evt) {
  handleIncomingNotification(evt);
}

Future<void> handleIncomingNotification(NotificationEvent evt) async {
  final pkg = evt.packageName ?? '';
  if (!ExpenseParser.bankPackages.containsKey(pkg)) return;
  final text = [evt.title, evt.text].where((s) => s != null && s.isNotEmpty).join(' ');
  final parsed = ExpenseParser.parse(text, source: pkg, fallbackDate: DateTime.now());
  if (parsed == null) return;
  await DbService.saveParsed(parsed, sourceType: 'NOTIFICATION', raw: text);
}
