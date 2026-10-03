import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:permission_handler/permission_handler.dart';

/// İlk açılışta SMS ve Bildirim Erişimi izinlerini adım adım ister.
class PermissionScreen extends StatefulWidget {
  final Future<void> Function() onDone;
  const PermissionScreen({super.key, required this.onDone});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  int _step = 0;
  bool _smsOk = false;
  bool _notifOk = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ayarlar ekranından dönünce durumu tazele.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final sms = await Permission.sms.isGranted;
    final notif = (await NotificationsListener.hasPermission) ?? false;
    if (!mounted) return;
    setState(() {
      _smsOk = sms;
      _notifOk = notif;
      if (sms && _step == 0) _step = 1;
    });
  }

  Future<void> _askSms() async {
    final r = await Permission.sms.request();
    if (r.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _refresh();
    if (_smsOk) setState(() => _step = 1);
  }

  Future<void> _askNotif() async {
    await NotificationsListener.openPermissionSettings();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 72, color: cs.primary),
                const SizedBox(height: 16),
                Text('Hoş geldin', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Harcamaların otomatik kaydedilmesi için iki izne ihtiyaç var. '
                  'Veriler yalnızca bu cihazda saklanır.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                _StepCard(
                  index: 1,
                  active: _step == 0,
                  done: _smsOk,
                  icon: Icons.sms_rounded,
                  title: 'SMS Okuma İzni',
                  text: 'Bankanın gönderdiği harcama SMS\'lerini otomatik ayrıştırmak için gerekli.',
                  button: 'SMS iznini ver',
                  onPressed: _askSms,
                ),
                const SizedBox(height: 12),
                _StepCard(
                  index: 2,
                  active: _step == 1,
                  done: _notifOk,
                  icon: Icons.notifications_active_rounded,
                  title: 'Bildirim Erişimi',
                  text: 'Banka uygulamalarının push bildirimlerini okumak için. Açılan listeden '
                      '"Bütçe Takip"i bulup etkinleştir, sonra geri dön.',
                  button: 'Ayarları aç',
                  onPressed: _askNotif,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: (_smsOk || _notifOk) ? widget.onDone : null,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Devam et'),
                  ),
                ),
                TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Şimdilik atla'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final bool active;
  final bool done;
  final IconData icon;
  final String title;
  final String text;
  final String button;
  final VoidCallback onPressed;

  const _StepCard({
    required this.index,
    required this.active,
    required this.done,
    required this.icon,
    required this.title,
    required this.text,
    required this.button,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: active ? 3 : 0,
      color: done ? cs.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(done ? Icons.check_circle_rounded : icon, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('$index. $title', style: Theme.of(context).textTheme.titleMedium)),
            ]),
            const SizedBox(height: 8),
            Text(text),
            if (!done) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(onPressed: onPressed, child: Text(button)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
