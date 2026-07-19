import 'package:flutter/material.dart';
import '../models/kit.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import 'kit_detail_screen.dart';

class KitListScreen extends StatefulWidget {
  const KitListScreen({super.key});

  @override
  State<KitListScreen> createState() => _KitListScreenState();
}

class _KitListScreenState extends State<KitListScreen> {
  late Future<List<Kit>> _kitsFuture;

  @override
  void initState() {
    super.initState();
    _kitsFuture = ProductService.getKits();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tous les Kits'),
        backgroundColor: isDark ? Colors.grey[900] : primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Kit>>(
        future: _kitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun kit disponible pour le moment.'));
          }

          final kits = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: kits.length,
            itemBuilder: (context, index) {
              return _buildKitGridItem(context, kits[index], isDark, textColor, primaryColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildKitGridItem(BuildContext context, Kit kit, bool isDark, Color textColor, Color primaryColor) {
    final cardColor = isDark ? Colors.grey[850] : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KitDetailScreen(kit: kit)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.transparent),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: kit.image != null
                    ? Image.network(
                        kit.image!.startsWith('http') ? kit.image! : '${AuthService.baseUrl}${kit.image}',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                      )
                    : Container(
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.inventory, color: Colors.grey, size: 50),
                      ),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            kit.promoType == 'pourcentage' ? '-${kit.promoValeur}%' : '-${kit.promoValeur}F',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${kit.prixFinal} F',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
