import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/themes/app_theme.dart';
import 'core/routing/app_router.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'services/storage/offline_storage_service.dart';
import 'services/connectivity/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize offline storage service
  await OfflineStorageService.initialize();
  
  // Initialize connectivity service
  await ConnectivityService.initialize();
  
  runApp(
    const ProviderScope(
      child: LudoGameApp(),
    ),
  );
}

class LudoGameApp extends ConsumerWidget {
  const LudoGameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentTheme = ref.watch(currentFlutterThemeProvider);
    
    return MaterialApp.router(
      title: 'Ludo Game',
      debugShowCheckedModeBanner: false,
      theme: currentTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
