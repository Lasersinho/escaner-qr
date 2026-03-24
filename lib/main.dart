import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/presentation/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for optimal scanner UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Create the container so we can check the existing session *before*
  // the first frame is rendered.
  final container = ProviderContainer();
  await container.read(authProvider.notifier).checkSession();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OfficeFlowApp(),
    ),
  );
}
