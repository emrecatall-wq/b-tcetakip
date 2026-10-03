import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

import 'screens/dashboard_screen.dart';
import 'screens/permission_screen.dart';
import 'services/background_handlers.dart';
import 'services/db_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  await DbService.open();
  NotificationsListener.initialize(callbackHandle: notificationBackgroundHandler);
  runApp(const ButceTakipApp());
}

class ButceTakipApp extends StatelessWidget {
  const ButceTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bütçe Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B7F5C),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B7F5C),
        brightness: Brightness.dark,
      ),
      home: const Gate(),
    );
  }
}

/// İzinler tamamsa dashboard'a, değilse izin ekranına yönlendirir.
class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  bool? _ready;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final sms = await Permission.sms.isGranted;
    final notif = (await NotificationsListener.hasPermission) ?? false;
    if (sms) _startSmsListener();
    if (notif) await _startNotificationService();
    if (mounted) setState(() => _ready = sms || notif);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_ready == true) return const DashboardScreen();
    return PermissionScreen(onDone: _check);
  }
}

void _startSmsListener() {
  Telephony.instance.listenIncomingSms(
    onNewMessage: (m) => handleIncomingSms(m),
    onBackgroundMessage: smsBackgroundHandler,
    listenInBackground: true,
  );
}

Future<void> _startNotificationService() async {
  final running = (await NotificationsListener.isRunning) ?? false;
  if (!running) {
    await NotificationsListener.startService(
      foreground: false,
      title: 'Bütçe Takip',
      description: 'Banka bildirimleri dinleniyor',
    );
  }
}
