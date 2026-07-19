import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import 'admin_promotion_create_screen.dart';

class AdminPromotionListScreen extends StatefulWidget {
  const AdminPromotionListScreen({super.key});

  @override
  State<AdminPromotionListScreen> createState() => _AdminPromotionListScreenState();
}

class _AdminPromotionListScreenState extends State<AdminPromotionListScreen> {
  late Future<List<dynamic>> _promotionsFuture;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  void _loadPromotions() {
    setState(() {
      _promotionsFuture = AdminApiService.getPromotions();
    });
  }

  Future<void> _deletePromotion(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette promotion ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminApiService.deletePromotion(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion supprimée')));
          _loadPromotions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Promotions Actives'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _promotionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}', style: TextStyle(color: textColor)));
          }
          final promotions = snapshot.data ?? [];
          if (promotions.isEmpty) {
            return Center(child: Text('Aucune promotion active.', style: TextStyle(color: textColor)));
          }

          return ListView.builder(
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.local_offer, color: isDark ? primaryColor : Colors.deepPurple),
                  title: Text(
                    'Réduction: -${promo['valeur']}${promo['type_reduction'] == 'pourcentage' ? '%' : ' F'}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  subtitle: Text('ID Cible: ${promo['object_id']} | Type: ${promo['content_type_model']}', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminPromotionCreateScreen(promoToEdit: promo),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadPromotions();
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePromotion(promo['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? primaryColor : Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminPromotionCreateScreen()),
          ).then((_) => _loadPromotions());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
