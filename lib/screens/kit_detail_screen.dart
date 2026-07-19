import 'package:flutter/material.dart';
import '../../models/kit.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';

class KitDetailScreen extends ConsumerWidget {
  final Kit kit;

  const KitDetailScreen({super.key, required this.kit});

  void _addToCart(BuildContext context) async {
    try {
      await ProductService.addToCart(
        contentType: 'kit',
        objectId: kit.id,
        quantite: 1,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le kit a été ajouté au panier !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(kit.nom),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, size: 24),
                onPressed: () {
                  ref.read(selectedTabProvider.notifier).setTab(2);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final itemCount = ref.watch(cartBadgeProvider);
                  if (itemCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text('$itemCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kit.image != null)
              Image.network(
                kit.image!.startsWith('http')
                    ? kit.image!
                    : '${AuthService.baseUrl}${kit.image}',
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 250, color: Colors.grey[200]),
              )
            else
              Container(
                height: 250,
                color: Colors.grey[300],
                child: const Icon(Icons.inventory, size: 80, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kit.nom,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  if (kit.enPromotion) ...[
                    Text(
                      '${kit.prixTotal} F',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '${kit.prixFinal} F',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Text(
                      '${kit.prixTotal} F',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (kit.description.isNotEmpty) ...[
                    Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                    const SizedBox(height: 8),
                    Text(kit.description, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87)),
                    const SizedBox(height: 24),
                  ],
                  Text('Contenu du Kit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                  const SizedBox(height: 12),
                  ...kit.items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isDark ? Colors.grey[850] : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? primaryColor : Colors.deepPurple,
                            child: const Icon(Icons.check, color: Colors.white, size: 16),
                          ),
                          title: Text(item.variante.desc, style: TextStyle(color: textColor)),
                          trailing: Text('x${item.quantite}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _addToCart(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ajouter au panier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
