import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';

/// Notifier pour l'onglet actif
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

/// Provider pour contrôler l'onglet actif depuis n'importe quel écran
final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(SelectedTabNotifier.new);

/// Provider du panier — AsyncNotifier
final cartProvider = AsyncNotifierProvider<CartNotifier, Cart?>(CartNotifier.new);

class CartNotifier extends AsyncNotifier<Cart?> {
  @override
  Future<Cart?> build() async {
    try {
      return await CartService.getCart();
    } catch (_) {
      return null;
    }
  }

  /// Recharger le panier depuis l'API
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => CartService.getCart());
  }

  /// Ajouter un article (variante ou kit)
  Future<String?> addItem({
    required String contentType,
    required int objectId,
    int quantite = 1,
  }) async {
    try {
      final cart = await CartService.addItem(
        contentType: contentType,
        objectId: objectId,
        quantite: quantite,
      );
      state = AsyncData(cart);
      return null; // succès
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Augmenter la quantité d'un article
  Future<void> increment(CartItem cartItem) async {
    final newQty = cartItem.quantite + 1;
    if (newQty > cartItem.stockDisponible) return;
    try {
      final cart = await CartService.updateQuantity(
        cartItemId: cartItem.id,
        quantite: newQty,
      );
      state = AsyncData(cart);
    } catch (_) {}
  }

  /// Diminuer la quantité d'un article (min = 1)
  Future<void> decrement(CartItem cartItem) async {
    final newQty = cartItem.quantite - 1;
    if (newQty <= 0) {
      await remove(cartItem);
      return;
    }
    try {
      final cart = await CartService.updateQuantity(
        cartItemId: cartItem.id,
        quantite: newQty,
      );
      state = AsyncData(cart);
    } catch (_) {}
  }

  /// Supprimer un article du panier
  Future<void> remove(CartItem cartItem) async {
    try {
      final cart = await CartService.removeItem(cartItem.id);
      state = AsyncData(cart);
    } catch (_) {}
  }

  /// Valider la commande
  Future<String?> checkout(Map<String, dynamic> payload) async {
    try {
      await CartService.checkout(payload);
      // Vider le panier localement en rechargeant (ou en le mettant à null)
      state = const AsyncData(null); 
      return null; // Succès
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Nombre total d'articles (pour le badge navbar)
  int get totalItems {
    return state.value?.totalItems ?? 0;
  }
}

/// Provider simple pour le badge de la navbar
final cartBadgeProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartProvider);
  return cartState.value?.totalItems ?? 0;
});
