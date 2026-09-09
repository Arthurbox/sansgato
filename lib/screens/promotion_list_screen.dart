import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../models/kit.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import 'kit_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PromotionListScreen extends StatefulWidget {
  const PromotionListScreen({super.key});

  @override
  State<PromotionListScreen> createState() => _PromotionListScreenState();
}

class _PromotionListScreenState extends State<PromotionListScreen> {
  late Future<Map<String, dynamic>> _activePromotionsFuture;

  @override
  void initState() {
    super.initState();
    _activePromotionsFuture = ProductService.getActivePromotions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('⚡ Ventes Flash'),
        backgroundColor: isDark ? Colors.grey[900] : primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _activePromotionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Aucune promotion active.'));
          }

          final List<Product> promoProducts = snapshot.data!['products'] ?? [];
          final List<Kit> promoKits = snapshot.data!['kits'] ?? [];

          if (promoProducts.isEmpty && promoKits.isEmpty) {
            return const Center(child: Text('Aucune promotion active pour le moment.'));
          }

          final int totalItems = promoProducts.length + promoKits.length;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              if (index < promoProducts.length) {
                return _buildFlashSaleProductGridItem(context, promoProducts[index], isDark, textColor, primaryColor);
              } else {
                final kitIndex = index - promoProducts.length;
                return _buildKitGridItem(context, promoKits[kitIndex], isDark, textColor, primaryColor);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildFlashSaleProductGridItem(BuildContext context, Product product, bool isDark, Color textColor, Color primaryColor) {
    final variant = product.variantes.isNotEmpty ? product.variantes.first : null;
    final String imageUrl = product.images.isNotEmpty ? product.images.first.image : '';
    final cardColor = isDark ? Colors.grey[850] : Colors.white;

    return GestureDetector(
      onTap: () {
        // Todo: Navigate to ProductDetailScreen
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.transparent),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(imageUrl: imageUrl.startsWith('http') ? imageUrl : '${AuthService.baseUrl}$imageUrl', width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()), errorWidget: (context, url, error) => const Icon(Icons.error)),
                    )
                  else
                    Container(
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.inventory, color: Colors.grey, size: 50),
                    ),
                  if (variant != null && variant.enPromotion)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          variant.promoType == 'pourcentage' ? '-${variant.promoValeur}%' : '-${variant.promoValeur}F',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nomComplet,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (variant != null && variant.enPromotion) ...[
                    Text(
                      '${variant.prixInitial} F',
                      style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11),
                    ),
                    Text(
                      '${variant.prixFinal} F',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKitGridItem(BuildContext context, Kit kit, bool isDark, Color textColor, Color primaryColor) {
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    return GestureDetector(
      onTap: () {
        context.push('/kit/${kit.id}', extra: kit);
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.transparent),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: kit.image != null
                        ? CachedNetworkImage(imageUrl: kit.image!.startsWith('http') ? kit.image! : '${AuthService.baseUrl}${kit.image}', width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()), errorWidget: (context, url, error) => const Icon(Icons.error))
                        : Container(
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.inventory, color: Colors.grey, size: 50),
                          ),
                  ),
                  if (kit.enPromotion)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          kit.promoType == 'pourcentage' ? '-${kit.promoValeur}%' : '-${kit.promoValeur}F',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kit.nom,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (kit.enPromotion) ...[
                    Text(
                      '${kit.prixFinal} F',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ] else ...[
                    Text(
                      '${kit.prixTotal} F',
                      style: TextStyle(color: isDark ? primaryColor : Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
