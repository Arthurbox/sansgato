import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'utils/global_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise les données de localisation pour DateFormat (fr_FR, etc.)
  await initializeDateFormatting('fr_FR', null);
  await AuthService.init();
  ApiClient.initialize();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Erreur d\'initialisation Firebase: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Sansgato',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
        Locale('en', ''),
      ],
      home: AuthService.isAuthenticated ? const MainScaffold() : const LoginScreen(),
    );
  }
}
