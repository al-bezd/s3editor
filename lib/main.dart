import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:s3editor/const.dart';
import 'package:s3editor/notifiers/bootstrap_notifier.dart';
import 'package:s3editor/screens/loading_screen.dart';
import 'package:s3editor/screens/s3_browser_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // На web аудиодвижок может быть недоступен (нужен пользовательский жест /
  // определённые заголовки) — не даём этому уронить всё приложение.
  try {
    await SoLoud.instance.init();
  } catch (e) {
    debugPrint('SoLoud init failed: $e');
  }
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S3 Client',
      navigatorKey: globalNavigatorKey,
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blue)
        ),
      home: Consumer(
        builder: (context, ref, _) {
          final bootstrapIsLoading = ref.watch(
            bootstrapProvider.select((x) => x.isLoading),
          );

          if (bootstrapIsLoading) {
            return const LoadingScreen();
          }
          return const S3BrowserScreen();
        },
      ),
    );
  }
}
