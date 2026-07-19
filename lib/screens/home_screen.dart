import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/swipeable_add_to_cart_button.dart';
import '../widgets/feed_skeleton_loader.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      _searchQuery = query;
    });
  }


  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(_searchQuery));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDark),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(child: Text('Aucun produit disponible.'));
                  }
                  return _buildFeed(products, isDark);
                },
                loading: () => FeedSkeletonLoader(isDark: isDark),
                error: (err, stack) => Center(child: Text('Erreur: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final hint = isDark ? Colors.grey[500] : Colors.grey[400];
    final iconColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final searchBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.menu, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _search,
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  hintText: 'Chercher des produits, marques...',
                  hintStyle: TextStyle(fontSize: 13, color: hint),
                  prefixIcon: Icon(Icons.search, color: hint, size: 18),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.person_outline, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined, color: iconColor, size: 24),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('1', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(List<Product> products, bool isDark) {
    List<Widget> items = [];
    List<Product> portraitBuffer = [];

    void flushPortrait() {
      if (portraitBuffer.isEmpty) return;
      if (portraitBuffer.length == 1) {
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPortraitCard(portraitBuffer[0], isDark)),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        );
      } else {
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPortraitCard(portraitBuffer[0], isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildPortraitCard(portraitBuffer[1], isDark)),
              ],
            ),
          ),
        );
      }
      portraitBuffer.clear();
    }

    for (final product in products) {
      final cat = product.categorie?.nom.toLowerCase() ?? '';
      final isLandscape = cat.contains('television') ||
          cat.contains('télévision') ||
          cat.contains('ordinateur') ||
          cat.contains('velo') ||
          cat.contains('vélo');

      if (isLandscape) {
        flushPortrait();
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildLandscapeCard(product, isDark),
          ),
        );
      } else {
        portraitBuffer.add(product);
        if (portraitBuffer.length == 2) flushPortrait();
      }
    }
    flushPortrait();

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      children: items,
    );
  }

  Widget _buildPortraitCard(Product product, bool isDark) {
    final imageUrl = _firstImageUrl(product);
    final variant = product.variantes.isNotEmpty ? product.variantes.first : null;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey[400] : Colors.grey[600];

    // Vérifier si le produit est dans le panier
    final cartAsync = ref.watch(cartProvider);
    bool isAdded = false;
    if (variant != null && cartAsync.value != null) {
      for (var cartItem in cartAsync.value!.items) {
        if (cartItem.itemType == 'productvariant' && cartItem.item.id == variant.id) {
          isAdded = true;
          break;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isAdded ? Border.all(color: const Color(0xFF00A9C1), width: 1.5) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  left: 8,
                  child: _stateBadge(product.etat),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                      ),
                      child: Icon(Icons.favorite_border, size: 15, color: subColor),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nomComplet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (variant != null) ...[
                    if (variant.enPromotion)
                      Text(
                        '${variant.prixInitial} F',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      '${variant.prixFinal} F',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildRatingRow(4.8, isDark),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SizedBox(
                          height: 36, // Slightly smaller height for portrait cards
                          child: SwipeableAddToCartButton(
                            isDark: isDark,
                            isAdded: isAdded,
                            onSwipe: () async {
                              if (variant == null) return false;
                              
                              final error = await ref.read(cartProvider.notifier).addItem(
                                contentType: 'productvariant',
                                objectId: variant.id,
                                quantite: 1,
                              );
                              
                              if (error == null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product.nomComplet} ajouté !'),
                                      backgroundColor: const Color(0xFF00A9C1),
                                      duration: const Duration(milliseconds: 1500),
                                    ),
                                  );
                                }
                                return true;
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                                  );
                                }
                                return false;
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeCard(Product product, bool isDark) {
    final imageUrl = _firstImageUrl(product);
    final variant = product.variantes.isNotEmpty ? product.variantes.first : null;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    // Vérifier si le produit est dans le panier
    final cartAsync = ref.watch(cartProvider);
    bool isAdded = false;
    if (variant != null && cartAsync.value != null) {
      for (var cartItem in cartAsync.value!.items) {
        if (cartItem.itemType == 'productvariant' && cartItem.item.id == variant.id) {
          isAdded = true;
          break;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isAdded ? Border.all(color: const Color(0xFF00A9C1), width: 1.5) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl.startsWith('http') ? imageUrl : '${AuthService.baseUrl}$imageUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(isDark),
                          )
                        : _imagePlaceholder(isDark),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: _stateBadge(product.etat),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nomComplet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (variant != null) ...[
                          if (variant.enPromotion)
                            Text(
                              '${variant.prixInitial} F',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '${variant.prixFinal} F',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        _buildRatingRow(4.7, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: SwipeableAddToCartButton(
                      isDark: isDark,
                      isAdded: isAdded,
                      onSwipe: () async {
                        final variant = product.variantes.isNotEmpty ? product.variantes.first : null;
                        if (variant == null) return false;
                        
                        final error = await ref.read(cartProvider.notifier).addItem(
                          contentType: 'productvariant',
                          objectId: variant.id,
                          quantite: 1,
                        );
                        
                        if (error == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.nomComplet} ajouté !'),
                                backgroundColor: const Color(0xFF00A9C1),
                                duration: const Duration(milliseconds: 1500),
                              ),
                            );
                          }
                          return true;
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                            );
                          }
                          return false;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstImageUrl(Product product) {
    for (final v in product.variantes) {
      if (v.images.isNotEmpty) return v.images.first.image;
    }
    return '';
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
      child: Icon(Icons.image_outlined, size: 40, color: isDark ? Colors.grey[700] : Colors.grey[400]),
    );
  }

  Widget _stateBadge(String etat) {
    final isNew = etat.toLowerCase() == 'neuf';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
      ),
      child: Text(
        isNew ? 'Neuf' : etat,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isNew ? const Color(0xFF1A1A1A) : Colors.orange[700],
        ),
      ),
    );
  }

  Widget _buildRatingRow(double rating, bool isDark) {
    return Row(
      children: [
        const Icon(Icons.star, color: Color(0xFFFFB800), size: 13),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
