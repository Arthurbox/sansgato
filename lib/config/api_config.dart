/// Centralise toutes les routes API de l'application.
/// Évite les erreurs de préfixe (/api/shop/ vs /api/) en un seul endroit.
class ApiConfig {
  // ─── Préfixes des apps ────────────────────────────────────────────────
  static const String _shop     = '/api/shop';
  static const String _accounts = '/api/accounts';

  // ─── Auth ─────────────────────────────────────────────────────────────
  static const String login    = '$_accounts/login/';
  static const String register = '$_accounts/register/';
  static const String profile  = '$_accounts/profile/';

  // ─── Produits ─────────────────────────────────────────────────────────
  static const String products   = '$_shop/products/';
  static String productDetail(int id) => '$_shop/products/$id/';

  // ─── Catégories ───────────────────────────────────────────────────────
  static const String categories = '$_shop/categories/';

  // ─── Panier ───────────────────────────────────────────────────────────
  static const String cart     = '$_shop/cart/';
  static String cartItem(int id) => '$_shop/cart/$id/';
  static const String checkout = '$_shop/checkout/';

  // ─── Commandes ────────────────────────────────────────────────────────
  static const String orders = '$_shop/orders/';
  static String orderDetail(int id) => '$_shop/orders/$id/';

  // ─── Kits ─────────────────────────────────────────────────────────────
  static const String kits = '$_shop/kits/';
  static String kitDetail(int id) => '$_shop/kits/$id/';

  // ─── Promotions ───────────────────────────────────────────────────────
  static const String promotions = '$_shop/promotions/active/';

  // ─── Favoris ──────────────────────────────────────────────────────────
  static const String favorites    = '$_shop/favorites/';
  static const String favoritesIds = '$_shop/favorites/?ids=true';
  static String favoriteToggle(int id) => '$_shop/favorites/$id/toggle/';

  // ─── Notifications ────────────────────────────────────────────────────
  static const String notifications = '$_shop/notifications/';
  static String notificationRead(int id) => '$_shop/notifications/$id/read/';

  // ─── Avis Clients ─────────────────────────────────────────────────────
  static String productReviews(int productId) => '$_shop/products/$productId/avis/';
}
