import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/admin_api_service.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

import '../../models/kit.dart';

class KitItemFormData {
  Product? selectedProduct;
  ProductVariant? selectedVariant;
  int quantite = 1;
}

class AdminKitCreateScreen extends StatefulWidget {
  final Kit? kitToEdit;
  const AdminKitCreateScreen({super.key, this.kitToEdit});

  @override
  State<AdminKitCreateScreen> createState() => _AdminKitCreateScreenState();
}

class _AdminKitCreateScreenState extends State<AdminKitCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descController = TextEditingController();
  final _prixController = TextEditingController();

  XFile? _selectedImage;
  bool _isLoading = false;

  List<Product> _allProducts = [];
  List<KitItemFormData> _kitItems = [KitItemFormData()];

  @override
  void initState() {
    super.initState();
    if (widget.kitToEdit != null) {
      _nomController.text = widget.kitToEdit!.nom;
      _descController.text = widget.kitToEdit!.description;
      _prixController.text = widget.kitToEdit!.prixTotal;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.getProducts();
      // Fetch full details for each product to get variants
      List<Product> fullProducts = [];
      for (var p in products) {
        fullProducts.add(await ProductService.getProductDetail(p.id));
      }
      
      List<KitItemFormData> initialItems = [KitItemFormData()];
      if (widget.kitToEdit != null && widget.kitToEdit!.items.isNotEmpty) {
        initialItems = widget.kitToEdit!.items.map((item) {
          Product? prod;
          ProductVariant? variant;
          for (var p in fullProducts) {
            try {
              variant = p.variantes.firstWhere((v) => v.id == item.variante.id);
              prod = p;
              break;
            } catch (e) {
              // not found in this product
            }
          }
          return KitItemFormData()
            ..selectedProduct = prod
            ..selectedVariant = variant
            ..quantite = item.quantite;
        }).toList();
      }

      setState(() {
        _allProducts = fullProducts;
        if (widget.kitToEdit != null) {
          _kitItems = initialItems;
        }
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  void _addKitItem() {
    setState(() {
      _kitItems.add(KitItemFormData());
    });
  }

  void _removeKitItem(int index) {
    if (_kitItems.length > 1) {
      setState(() {
        _kitItems.removeAt(index);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    for (var item in _kitItems) {
      if (item.selectedVariant == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une variante pour chaque article du kit')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final kitData = {
        'nom': _nomController.text,
        'description': _descController.text,
        'prix_total': _prixController.text,
        'statut': 'actif',
      };

      int kitId;
      if (widget.kitToEdit != null) {
        kitId = widget.kitToEdit!.id;
        await AdminApiService.updateKit(kitId, kitData);
        // Optionally, we could try to remove old items, but for now we just add/update new ones
      } else {
        final createdKit = await AdminApiService.createKit(kitData);
        kitId = createdKit['id'];
      }

      for (var item in _kitItems) {
        await AdminApiService.addKitItem(kitId, item.selectedVariant!.id, item.quantite);
      }

      if (_selectedImage != null) {
        await AdminApiService.uploadKitImage(kitId, _selectedImage!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.kitToEdit != null ? 'Kit mis à jour!' : 'Kit créé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.kitToEdit != null ? 'Modifier Kit' : 'Nouveau Kit'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _allProducts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- IMAGE ---
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Ajouter une image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- INFORMATIONS ---
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(labelText: 'Nom du kit *'),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _prixController,
                      decoration: const InputDecoration(labelText: 'Prix total (F) *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 24),

                    // --- COMPOSANTS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Articles du Kit',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _addKitItem,
                          icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
                          label: const Text('Ajouter', style: TextStyle(color: Colors.deepPurple)),
                        ),
                      ],
                    ),
                    const Divider(),

                    ...List.generate(_kitItems.length, (index) {
                      final item = _kitItems[index];
                      return Card(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Article ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (_kitItems.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeKitItem(index),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<Product>(
                                decoration: const InputDecoration(
                                  labelText: 'Produit',
                                  labelStyle: TextStyle(overflow: TextOverflow.ellipsis),
                                ),
                                isExpanded: true,
                                initialValue: item.selectedProduct,
                                items: _allProducts
                                    .map((p) => DropdownMenuItem(value: p, child: Text(p.nomComplet)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    item.selectedProduct = val;
                                    item.selectedVariant = null;
                                  });
                                },
                              ),
                              if (item.selectedProduct != null) ...[
                                const SizedBox(height: 12),
                                DropdownButtonFormField<ProductVariant>(
                                  decoration: const InputDecoration(
                                    labelText: 'Variante',
                                    labelStyle: TextStyle(overflow: TextOverflow.ellipsis),
                                  ),
                                  isExpanded: true,
                                  initialValue: item.selectedVariant,
                                  items: item.selectedProduct!.variantes
                                      .map((v) => DropdownMenuItem(value: v, child: Text(v.desc)))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() => item.selectedVariant = val);
                                  },
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: item.quantite.toString(),
                                decoration: const InputDecoration(labelText: 'Quantité'),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  item.quantite = int.tryParse(val) ?? 1;
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? primaryColor : Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(widget.kitToEdit != null ? 'Enregistrer' : 'Créer le Kit', style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
