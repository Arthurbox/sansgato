import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../widgets/cart_skeleton_loader.dart';
import 'checkout_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    const Color primary = Color(0xFF00A9C1);
    final Color bg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111318) : Colors.grey.shade50;
    final Color cardBg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F2A) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: cartAsync.when(
          loading: () => const CartSkeletonLoader(),
          error: (err, _) => _buildError(context, ref, err.toString()),
          data: (cart) {
            if (cart == null || cart.items.isEmpty) {
              return _buildEmpty(context, ref, primary);
            }
            return _buildCart(context, ref, cart, primary, bg, cardBg);
          },
        ),
      ),
    );
  }

  // ─── Panier rempli ────────────────────────────────────────────────────────
  Widget _buildCart(
    BuildContext context,
    WidgetRef ref,
    Cart cart,
    Color primary,
    Color bg,
    Color cardBg,
  ) {
    return Column(
      children: [
        // ── En-tête ──────────────────────────────────────────────────────────
        _buildHeader(context, ref, cart, primary),

        // ── Liste des articles ───────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              ...cart.items.map((item) => _buildCartItemCard(context, ref, item, primary, cardBg)),
              const SizedBox(height: 16),
              _buildSummaryCard(context, cart, primary, cardBg),
              const SizedBox(height: 100), // espace pour le bouton sticky
            ],
          ),
        ),

        // ── Bouton Commander ─────────────────────────────────────────────────
        _buildCheckoutButton(context, cart, primary),
      ],
    );
  }

  // ─── En-tête ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, WidgetRef ref, Cart cart, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mon Panier',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${cart.totalItems} article${cart.totalItems > 1 ? 's' : ''}',
                style: const TextStyle(color: Color(0xFF00A9C1), fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          // Bouton vider le panier
          if (cart.items.isNotEmpty)
            GestureDetector(
              onTap: () => _confirmClearCart(context, ref),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Carte article ────────────────────────────────────────────────────────
  Widget _buildCartItemCard(
    BuildContext context,
    WidgetRef ref,
    CartItem cartItem,
    Color primary,
    Color cardBg,
  ) {
    final imageUrl = cartItem.imageUrl;
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Image produit
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: imageUrl.startsWith('http')
                        ? imageUrl
                        : '${AuthService.baseUrl}$imageUrl', width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()), errorWidget: (context, url, error) => const Icon(Icons.error))
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),

          // Infos article
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + bouton supprimer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        cartItem.nomProduit,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _confirmRemoveItem(context, ref, cartItem),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.close, color: Colors.redAccent, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Tag variante
                if (cartItem.varianteInfo.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cartItem.varianteInfo,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 10),

                // Stepper + prix
                Row(
                  children: [
                    // Bouton -
                    _stepperButton(
                      context,
                      icon: Icons.remove,
                      filled: false,
                      onTap: () => notifier.decrement(cartItem),
                    ),
                    // Quantité
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '${cartItem.quantite}',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Bouton +
                    _stepperButton(
                      context,
                      icon: Icons.add,
                      filled: true,
                      onTap: cartItem.quantite < cartItem.stockDisponible
                          ? () => notifier.increment(cartItem)
                          : null,
                    ),
                    const Spacer(),
                    // Prix total ligne
                    Text(
                      '${cartItem.totalPrice.toStringAsFixed(0)} F',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stepper bouton ───────────────────────────────────────────────────────
  Widget _stepperButton(
    BuildContext context, {
    required IconData icon,
    required bool filled,
    VoidCallback? onTap,
  }) {
    const Color primary = Color(0xFF00A9C1);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled ? primary : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled
              ? (onTap != null ? Colors.white : Colors.white38)
              : Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  // ─── Récapitulatif ────────────────────────────────────────────────────────
  Widget _buildSummaryCard(BuildContext context, Cart cart, Color primary, Color cardBg) {
    const Color textGrey = Color(0xFF8A8A9A);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow(context, 'Sous-total', '${cart.totalPrice.toStringAsFixed(0)} F', textGrey),
          const SizedBox(height: 8),
          _summaryRow(context, 'Frais', 'À l\'étape suivante', textGrey),
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (hors frais)',
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${cart.totalPrice.toStringAsFixed(0)} F',
                style: TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, Color textGrey) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textGrey, fontSize: 13)),
        Text(value, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─── Bouton Commander ─────────────────────────────────────────────────────
  Widget _buildCheckoutButton(BuildContext context, Cart cart, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111318) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF00A9C1),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A9C1).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _goToCheckout(context, cart),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Passer la commande',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Panier vide ──────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context, WidgetRef ref, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          Text(
            'Votre panier est vide',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits pour commencer',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Naviguer vers l'onglet Accueil (index 0)
              ref.read(selectedTabProvider.notifier).setTab(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: Text('Parcourir les produits', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
          ),
        ],
      ),
    );
  }

  // ─── Erreur ───────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Impossible de charger le panier', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(cartProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A9C1)),
            child: Text('Réessayer', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
          ),
        ],
      ),
    );
  }

  // ─── Image placeholder ────────────────────────────────────────────────────
  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFF2A2D3A),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    );
  }

  // ─── Dialogues ────────────────────────────────────────────────────────────
  Future<void> _confirmRemoveItem(BuildContext context, WidgetRef ref, CartItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Supprimer', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
        content: const Text(
          'Retirer cet article de votre panier ?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(cartProvider.notifier).remove(item);
    }
  }

  Future<void> _confirmClearCart(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Vider le panier', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
        content: const Text(
          'Supprimer tous les articles ?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vider', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final cart = ref.read(cartProvider).value;
      if (cart != null) {
        final notifier = ref.read(cartProvider.notifier);
        for (final item in cart.items) {
          await notifier.remove(item);
        }
      }
    }
  }

  void _goToCheckout(BuildContext context, Cart cart) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }
}
