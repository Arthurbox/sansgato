import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../models/kit.dart';
import '../../services/product_service.dart';
import '../../services/admin_api_service.dart';
import '../../services/auth_service.dart';
import '../../providers/product_provider.dart';
import 'admin_product_create_screen.dart';
import 'admin_product_variant_screen.dart';
import 'admin_product_edit_screen.dart';
import 'admin_kit_create_screen.dart';
import 'admin_promotion_list_screen.dart';

class AdminProductListScreen extends ConsumerStatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  ConsumerState<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends ConsumerState<AdminProductListScreen> {
  late Future<List<dynamic>> _categoriesFuture;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = AdminApiService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);

    return FutureBuilder<List<dynamic>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: Center(child: Text('Erreur: ${snapshot.error}', style: TextStyle(color: isDark ? Colors.white : Colors.black87))));
        }
        final categories = snapshot.data ?? [];
        
        return DefaultTabController(
          length: categories.length + 1,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Catalogue'),
              automaticallyImplyLeading: false,
              backgroundColor: isDark ? Colors.grey[900] : Colors.deepPurple,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.local_offer),
                  tooltip: 'Gérer les Promotions',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminPromotionListScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_box),
                  tooltip: 'Nouveau Kit',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminKitCreateScreen()),
                    ).then((_) {
                      setState(() {
                        _refreshKey++;
                      });
                      ref.invalidate(kitsProvider);
                    });
                  },
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  ...categories.map((c) => Tab(text: c['nom'])),
                  const Tab(text: 'Kits'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ...categories.map((c) => _CategoryProductList(
                  key: ValueKey('${c['id']}_$_refreshKey'), 
                  categoryId: c['id']
                )),
                _KitList(key: ValueKey('kits_$_refreshKey')),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: isDark ? primaryColor : Colors.deepPurple,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminProductCreateScreen()),
                ).then((_) {
                  setState(() {
                    _refreshKey++;
                    _categoriesFuture = AdminApiService.getCategories();
                  });
                  ref.invalidate(productsProvider);
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryProductList extends ConsumerStatefulWidget {
  final int categoryId;
  const _CategoryProductList({super.key, required this.categoryId});

  @override
  ConsumerState<_CategoryProductList> createState() => _CategoryProductListState();
}

class _CategoryProductListState extends ConsumerState<_CategoryProductList> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = ProductService.getProducts(categoryId: widget.categoryId);
    });
  }

  Future<void> _deleteProduct(int productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce produit ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminApiService.deleteProduct(productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produit supprimé avec succès')));
          _loadProducts();
          ref.invalidate(productsProvider);
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
    final textColor = isDark ? Colors.white : Colors.black87;

    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}', style: TextStyle(color: textColor)));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Center(child: Text('Aucun produit dans cette catégorie.', style: TextStyle(color: textColor)));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              color: isDark ? Colors.grey[850] : Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: Builder(
                  builder: (context) {
                    String? imageUrl;
                    if (product.images.isNotEmpty) {
                      imageUrl = product.images.first.image;
                    } else if (product.variantes.isNotEmpty && product.variantes.first.images.isNotEmpty) {
                      imageUrl = product.variantes.first.images.first.image;
                    }
                    
                    if (imageUrl != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          imageUrl.startsWith('http')
                              ? imageUrl
                              : '${AuthService.baseUrl}$imageUrl',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                        ),
                      );
                    }
                    return const Icon(Icons.smartphone, size: 50);
                  },
                ),
                title: Text(product.nomComplet, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text('${product.variantes.length} variante(s) | ${product.etat}', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminProductEditScreen(product: product),
                          ),
                        ).then((result) {
                          if (result == true) {
                            _loadProducts();
                            ref.invalidate(productsProvider);
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(product.id),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProductVariantScreen(product: product),
                    ),
                  ).then((_) {
                    _loadProducts();
                    ref.invalidate(productsProvider);
                  });
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _KitList extends ConsumerStatefulWidget {
  const _KitList({super.key});

  @override
  ConsumerState<_KitList> createState() => _KitListState();
}

class _KitListState extends ConsumerState<_KitList> {
  late Future<List<Kit>> _kitsFuture;

  @override
  void initState() {
    super.initState();
    _loadKits();
  }

  void _loadKits() {
    setState(() {
      _kitsFuture = ProductService.getKits();
    });
  }

  Future<void> _deleteKit(int kitId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce kit ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminApiService.deleteKit(kitId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kit supprimé avec succès')));
          _loadKits();
          ref.invalidate(kitsProvider);
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
    final textColor = isDark ? Colors.white : Colors.black87;

    return FutureBuilder<List<Kit>>(
      future: _kitsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}', style: TextStyle(color: textColor)));
        }
        final kits = snapshot.data ?? [];
        if (kits.isEmpty) {
          return Center(child: Text('Aucun kit disponible.', style: TextStyle(color: textColor)));
        }

        return ListView.builder(
          itemCount: kits.length,
          itemBuilder: (context, index) {
            final kit = kits[index];
            return Card(
              color: isDark ? Colors.grey[850] : Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: kit.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          kit.image!.startsWith('http')
                              ? kit.image!
                              : '${AuthService.baseUrl}${kit.image!}',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                        ),
                      )
                    : const Icon(Icons.inventory_2, size: 50),
                title: Text(kit.nom, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text('${kit.items.length} produit(s) | ${kit.prixTotal} F', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminKitCreateScreen(kitToEdit: kit),
                          ),
                        ).then((result) {
                          if (result == true) {
                            _loadKits();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteKit(kit.id),
                    ),
                  ],
                ),
                onTap: null,
              ),
            );
          },
        );
      },
    );
  }
}
