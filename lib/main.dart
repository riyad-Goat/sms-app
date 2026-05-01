import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';

const String TELEGRAM_TOKEN = 'ضع_التوكن_هنا';
const String CHAT_ID = 'ضع_الشات_ايدي_هنا';

Future<void> sendToTelegram(String message) async {
  final url = Uri.parse(
    'https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage'
  );
  await http.post(url, body: {
    'chat_id': CHAT_ID,
    'text': message,
  });
}

@pragma('vm:entry-point')
void onBackgroundMessage(SmsMessage message) {
  final text = '📱 SMS جديد\n'
      'من: ${message.address}\n'
      'الرسالة: ${message.body}';
  sendToTelegram(text);
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  final telephony = Telephony.instance;
  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) {
      final text = '📱 SMS جديد\n'
          'من: ${message.address}\n'
          'الرسالة: ${message.body}';
      sendToTelegram(text);
    },
    onBackgroundMessage: onBackgroundMessage,
  );
}

Future<void> initService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'sms_forwarder',
      initialNotificationTitle: 'SMS Forwarder',
      initialNotificationContent: 'يعمل في الخلفية...',
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
  await service.startService();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initService();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _serviceRunning = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _serviceRunning ? Icons.sms : Icons.sms_failed,
                size: 80,
                color: _serviceRunning ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(height: 20),
              Text(
                _serviceRunning ? 'يعمل ✓' : 'متوقف',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SMS Forwarder',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  await sendToTelegram('✅ اختبار - التطبيق يعمل بشكل صحيح!');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال رسالة اختبار!')),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('إرسال اختبار'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}