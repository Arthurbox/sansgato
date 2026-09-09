import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sansgato/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Tests', () {
    testWidgets('App starts and shows Login or Home Screen', (tester) async {
      app.main();
      
      // Attendre que l'application s'initialise (Firebase, etc.)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // On vérifie si on est sur l'écran de connexion ou l'écran principal
      final hasLogin = find.text('S\'inscrire').evaluate().isNotEmpty || find.text('Se connecter').evaluate().isNotEmpty;
      final hasHome = find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      
      expect(hasLogin || hasHome, isTrue, reason: 'L\'application doit afficher l\'écran de connexion ou l\'écran d\'accueil.');
    });

    testWidgets('Navigation bar verification', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final hasHome = find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      if (hasHome) {
        // Si on est connecté, on vérifie la présence de la barre de navigation
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      } else {
        // Si non connecté, on vérifie qu'on est bien sur l'écran de login
        expect(find.byType(TextFormField).evaluate().isNotEmpty, isTrue);
      }
    });
  });
}
