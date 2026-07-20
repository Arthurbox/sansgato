import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/favorite_service.dart';
import '../services/auth_service.dart';
import '../providers/favorite_provider.dart';
import '../providers/cart_provider.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final products = await FavoriteService.fetchFavoriteProducts();
      if (mounted) setState(() { _products = products; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _formatPrice(String rawPrice) {
    try {
      final value = double.parse(rawPrice);
      final intValue = value.round();
      final formatted = intValue.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
      return '$formatted F';
    } catch (_) {
      return '$rawPrice F';
    }
  }

  String _firstImageUrl(Product product) {
    for (final v in product.variantes) {
      if (v.images.isNotEmpty) return v.images.first.image;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Mes Favoris',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading && _products.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_products.length} produit${_products.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A9C1)))
                  : _error != null
                      ? _buildError()
                      : _products.isEmpty
                          ? _buildEmpty(isDark, subColor)
                          : RefreshIndicator(
                              onRefresh: _loadFavorites,
                              color: const Color(0xFF00A9C1),
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: _products.length,
                                itemBuilder: (context, index) {
                                  return _buildProductCard(_products[index], isDark, cardColor, textColor, subColor);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isDark, Color cardColor, Color textColor, Color subColor) {
    final imageUrl = _firstImageUrl(product);
    final variant = product.variantes.isNotEmpty ? product.variantes.first : null;
    final isFav = ref.watch(favoriteProvider).contains(product.id);

    // Vérifier si déjà dans le panier
    final cartAsync = ref.watch(cartProvider);
    bool isAdded = false;
    if (variant != null && cartAsync.value != null) {
      for (var item in cartAsync.value!.items) {
        if (item.itemType == 'productvariant' && item.item.id == variant.id) {
          isAdded = true;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + bouton cœur
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl.startsWith('http') ? imageUrl : '${AuthService.baseUrl}$imageUrl',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(isDark),
                          )
                        : _imagePlaceholder(isDark),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await ref.read(favoriteProvider.notifier).toggleFavorite(product.id);
                      // Retirer de la liste locale
                      setState(() {
                        _products.removeWhere((p) => p.id == product.id);
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isFav ? Colors.red : cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFav ? Colors.white : subColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Infos produit
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nomComplet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    if (variant != null) ...[
                      if (variant.enPromotion)
                        Text(
                          _formatPrice(variant.prixInitial),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _formatPrice(variant.prixFinal),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: variant.enPromotion ? Colors.red : textColor,
                              ),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: isAdded ? null : () async {
                              final error = await ref.read(cartProvider.notifier).addItem(
                                contentType: 'productvariant',
                                objectId: variant.id,
                                quantite: 1,
                              );
                              if (error == null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.nomComplet} ajouté !'),
                                    backgroundColor: const Color(0xFF00A9C1),
                                    duration: const Duration(milliseconds: 1500),
                                  ),
                                );
                              } else if (error != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAdded ? null : (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A)),
                                gradient: isAdded
                                    ? const LinearGradient(
                                        colors: [Color(0xFF00A9C1), Color(0xFF00899D)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAdded ? const Color(0xFF00A9C1) : Colors.black).withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isAdded ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                                color: isAdded ? Colors.white : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color subColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 72, color: subColor.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Aucun favori pour l\'instant',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: subColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur le cœur d\'un produit\npour le sauvegarder ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('Impossible de charger les favoris', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadFavorites,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A9C1)),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
      child: Icon(Icons.image_outlined, size: 40, color: isDark ? Colors.grey[700] : Colors.grey[400]),
    );
  }
}
