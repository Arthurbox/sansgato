import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
import '../models/kit.dart';

// Screens
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/social_phone_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/product_detail_screen.dart';
import '../screens/kit_detail_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/promotion_list_screen.dart';
import '../screens/kit_list_screen.dart';
import '../screens/admin_main_screen.dart';

/// Noms des routes (constantes pour éviter les typos)
abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const socialPhone = '/social-phone';
  static const home = '/';
  static const productDetail = '/product/:id';
  static const kitDetail = '/kit/:id';
  static const checkout = '/checkout';
  static const notifications = '/notifications';
  static const promotions = '/promotions';
  static const kits = '/kits';
  static const admin = '/admin';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,

  /// Redirection globale basée sur l'état d'authentification
  redirect: (BuildContext context, GoRouterState state) {
    final isAuthenticated = AuthService.isAuthenticated;
    final isAuthRoute = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.otp ||
        state.matchedLocation == AppRoutes.socialPhone;

    // Non connecté et essaie d'accéder à une route protégée
    if (!isAuthenticated && !isAuthRoute) {
      return AppRoutes.login;
    }
    // Connecté et essaie d'accéder à une route d'auth
    if (isAuthenticated && isAuthRoute) {
      return AppRoutes.home;
    }
    return null; // Pas de redirection
  },

  routes: [
    // --- Authentification ---
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      name: 'otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OtpScreen(
          phoneNumber: extra['phoneNumber'] as String,
          purpose: extra['purpose'] as String,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.socialPhone,
      name: 'social-phone',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SocialPhoneScreen(
          email: extra['email'] as String,
          name: extra['name'] as String,
          provider: extra['provider'] as String,
        );
      },
    ),

    // --- Application principale ---
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const MainScaffold(),
      routes: [
        // Détail produit : /product/:id  (passe l'objet Product via extra)
        GoRoute(
          path: 'product/:id',
          name: 'product-detail',
          builder: (context, state) {
            final product = state.extra as Product;
            return ProductDetailScreen(product: product);
          },
        ),
        // Détail kit : /kit/:id  (passe l'objet Kit via extra)
        GoRoute(
          path: 'kit/:id',
          name: 'kit-detail',
          builder: (context, state) {
            final kit = state.extra as Kit;
            return KitDetailScreen(kit: kit);
          },
        ),
        // Checkout
        GoRoute(
          path: 'checkout',
          name: 'checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        // Notifications
        GoRoute(
          path: 'notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        // Promotions
        GoRoute(
          path: 'promotions',
          name: 'promotions',
          builder: (context, state) => const PromotionListScreen(),
        ),
        // Liste des kits
        GoRoute(
          path: 'kits',
          name: 'kits',
          builder: (context, state) => const KitListScreen(),
        ),
        // Admin
        GoRoute(
          path: 'admin',
          name: 'admin',
          builder: (context, state) => const AdminMainScreen(),
        ),
      ],
    ),
  ],

  /// Page d'erreur par défaut
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page introuvable : ${state.error}'),
    ),
  ),
);
