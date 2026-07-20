import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/swipeable_add_to_cart_button.dart';
import '../widgets/feed_skeleton_loader.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';
import 'notifications_screen.dart';
import '../providers/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    final iconColor = isDark ? Colors.white70 : const Color(0xFF555555);
    final activeIconColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final searchBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    final hintColor = isDark ? Colors.grey[500]! : Colors.grey[400]!;
    final borderColor = _searchFocusNode.hasFocus
        ? const Color(0xFFFF3B30)
        : Colors.transparent;

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Logo / Menu
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.menu_rounded, color: activeIconColor, size: 26),
          ),
          const SizedBox(width: 12),

          // ── Barre de recherche premium ──
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: _searchFocusNode.hasFocus
                    ? [BoxShadow(color: const Color(0xFFFF3B30).withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.search_rounded,
                      key: ValueKey(_searchFocusNode.hasFocus),
                      color: _searchFocusNode.hasFocus ? const Color(0xFFFF3B30) : hintColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onSubmitted: _search,
                      onChanged: (v) => _search(v),
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: 'Recherche de produits...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: hintColor,
                        ),
                      ),
                      cursorColor: const Color(0xFFFF3B30),
                      cursorWidth: 2,
                      cursorRadius: const Radius.circular(1),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _search('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(Icons.cancel_rounded, color: hintColor, size: 18),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Icône profil
          Icon(Icons.person_outline_rounded, color: iconColor, size: 26),
          const SizedBox(width: 12),

          // Icône notification
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, color: iconColor, size: 26),
                Consumer(
                  builder: (context, ref, child) {
                    final notifState = ref.watch(notificationProvider);
                    if (notifState.unreadCount > 0) {
                      return Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Center(
                            child: Text(
                              '${notifState.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  } // fin _buildTopBar

  Widget _buildFeed(List<Product> products, bool isDark) {
    List<Widget> items = [];
    
    // 🔥 Promotions Carousel
    final promotedProducts = products.where((p) => p.variantes.any((v) => v.enPromotion)).toList();
    if (promotedProducts.isNotEmpty) {
      items.add(_buildPromoCarousel(promotedProducts, isDark));
    }

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
      final isLandscape = product.categorie?.layoutType == 'landscape' ||
          cat.contains('television') ||
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
                  child: Consumer(
                    builder: (context, ref, _) {
                      final isFav = ref.watch(favoriteProvider).contains(product.id);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final error = await ref.read(favoriteProvider.notifier).toggleFavorite(product.id);
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $error'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isFav ? Colors.red : cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border, 
                            size: 15, 
                            color: isFav ? Colors.white : subColor,
                          ),
                        ),
                      );
                    },
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
                  if (variant != null)
                    // Prix barré + prix final sur la même ligne si promo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (variant.enPromotion) ...[
                          Text(
                            _formatPrice(variant.prixInitial),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 1.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatPrice(variant.prixFinal),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: variant.enPromotion ? const Color(0xFFFF3B30) : textColor,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildRatingRow(4.8, isDark),
                        ),
                      ),
                      GestureDetector(
                        onTap: isAdded ? null : () async {
                          if (variant == null) return;
                          
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
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAdded ? null : (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A)), // Blanc sale en sombre, Noir en clair
                            gradient: isAdded
                                ? const LinearGradient(
                                    colors: [Color(0xFF00A9C1), Color(0xFF00899D)], // Couleur "Passer la commande"
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: (isAdded ? const Color(0xFF00A9C1) : Colors.black).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isAdded ? Icons.shopping_cart : Icons.shopping_cart_outlined, // Le panier reste visible (version pleine quand ajouté)
                            color: isAdded ? Colors.white : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                            size: 18,
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final isFav = ref.watch(favoriteProvider).contains(product.id);
                      final subColor = isDark ? Colors.grey[400] : Colors.grey[600];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final error = await ref.read(favoriteProvider.notifier).toggleFavorite(product.id);
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $error'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isFav ? Colors.red : cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border, 
                            size: 15, 
                            color: isFav ? Colors.white : subColor,
                          ),
                        ),
                      );
                    },
                  ),
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
                          // Prix barré + prix final sur la même ligne si promo
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (variant.enPromotion) ...[
                                Text(
                                  _formatPrice(variant.prixInitial),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                _formatPrice(variant.prixFinal),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: variant.enPromotion ? const Color(0xFFFF3B30) : textColor,
                                ),
                              ),
                            ],
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

  /// Formate un prix : supprime les décimales si elles sont nulles (.00)
  /// Ex: "50000.00" → "50 000 F", "49999.50" → "50 000 F" (arrondi)
  String _formatPrice(String rawPrice) {
    try {
      final value = double.parse(rawPrice);
      final intValue = value.round(); // arrondi à l'entier le plus proche
      // formatage avec séparateur de milliers
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

  Widget _buildPromoCarousel(List<Product> promos, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Ventes Flash',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              const Text(
                'Voir tout',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00A9C1),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 150,
                  child: _buildPromoCard(promos[index], isDark),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPromoCard(Product product, bool isDark) {
    final imageUrl = _firstImageUrl(product);
    final variant = product.variantes.firstWhere((v) => v.enPromotion, orElse: () => product.variantes.first);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    // Vérifier si le produit est dans le panier
    final cartAsync = ref.watch(cartProvider);
    bool isAdded = false;
    if (cartAsync.value != null) {
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
        border: Border.all(
            color: isAdded ? const Color(0xFF00A9C1) : const Color(0xFFFF3B30).withOpacity(0.5), 
            width: 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: (isAdded ? const Color(0xFF00A9C1) : const Color(0xFFFF3B30)).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
                  top: 6,
                  left: 6,
                  child: _stateBadge(product.etat),
                ),
                Positioned(
                  top: 2, // ~0.05 cm vers le haut
                  right: 4,
                  child: PromoBadge(
                    text: variant.promoType == 'pourcentage' && variant.promoValeur != null
                        ? '-${double.parse(variant.promoValeur!).toInt()}%'
                        : variant.promoType == 'montant' && variant.promoValeur != null
                            ? '-${double.parse(variant.promoValeur!).toInt()} F'
                            : 'PROMO',
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final isFav = ref.watch(favoriteProvider).contains(product.id);
                      final subColor = isDark ? Colors.grey[400] : Colors.grey[600];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final error = await ref.read(favoriteProvider.notifier).toggleFavorite(product.id);
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $error'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isFav ? Colors.red : cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border, 
                            size: 15, 
                            color: isFav ? Colors.white : subColor,
                          ),
                        ),
                      );
                    },
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatPrice(variant.prixInitial),
                              style: TextStyle(fontSize: 11, color: Colors.grey[500], decoration: TextDecoration.lineThrough, decorationThickness: 1.5),
                            ),
                            Text(
                              _formatPrice(variant.prixFinal),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFF3B30)),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: isAdded ? null : () async {
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
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAdded ? null : (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A)), // Blanc sale en sombre, Noir en clair
                            gradient: isAdded
                                ? const LinearGradient(
                                    colors: [Color(0xFF00A9C1), Color(0xFF00899D)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: (isAdded ? const Color(0xFF00A9C1) : Colors.black).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isAdded ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                            color: isAdded ? Colors.white : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                            size: 16,
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
}

class PromoBadge extends StatelessWidget {
  final String text;
  const PromoBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF9500)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B30).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
