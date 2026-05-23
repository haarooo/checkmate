import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app_router.dart';
import 'core/theme/app_colors.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Android에서는 바로 FCM token 확인
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final permission = await FirebaseMessaging.instance.requestPermission();
    debugPrint('FCM PERMISSION: ${permission.authorizationStatus}');

    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM TOKEN: $fcmToken');
  } else {
    debugPrint('Firebase initialized on ${kIsWeb ? 'Web' : defaultTargetPlatform.name}');
  }

  runApp(const ProviderScope(child: CheckmateApp()));
}

class CheckmateApp extends ConsumerWidget {
  const CheckmateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Checkmate',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
    );
  }
}