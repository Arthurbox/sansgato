import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/admin_api_service.dart';

class AdminProductVariantScreen extends StatefulWidget {
  final Product product;

  const AdminProductVariantScreen({super.key, required this.product});

  @override
  State<AdminProductVariantScreen> createState() => _AdminProductVariantScreenState();
}

class _AdminProductVariantScreenState extends State<AdminProductVariantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prixController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();

  int? _selectedColorId;
  String? _selectedRam;
  String? _selectedStorage;
  bool _isLoading = false;
  ProductVariant? _variantToEdit;

  List<dynamic> _colors = [];
  final List<String> _rams = ['4 GB', '6 GB', '8 GB', '12 GB', '16 GB', '24 GB', '32 GB'];
  final List<String> _storages = ['32 GB', '64 GB', '128 GB', '256 GB', '512 GB', '1 TB', '2 TB'];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final colors = await AdminApiService.getColors();
      setState(() {
        _colors = colors;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des options: $e');
    }
  }

  bool _isTelevision() {
    final catName = widget.product.categorie?.nom.toUpperCase() ?? '';
    return catName == 'TELEVISION' || catName == 'TV';
  }

  bool _isVentilator() {
    final catName = widget.product.categorie?.nom.toUpperCase() ?? '';
    return catName == 'VENTILATEUR';
  }

  bool _showsColor() {
    return !_isTelevision() && !_isVentilator();
  }

  bool _showsRamAndStorage() {
    final catName = widget.product.categorie?.nom.toUpperCase() ?? '';
    return catName == 'SMARTPHONE' || catName == 'TABLETTE' || catName == 'ORDINATEUR' || catName == 'COMPUTER' || catName == 'TABLET';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_showsColor() && _selectedColorId == null) ||
        (_showsRamAndStorage() && (_selectedRam == null || _selectedStorage == null))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir toutes les options requises pour cette catégorie')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final variantData = {
        'produit': widget.product.id,
        'couleur': _selectedColorId,
        'ram': _selectedRam,
        'stockage': _selectedStorage,
        'prix': _prixController.text,
        'stock': _stockController.text,
        'sku': _skuController.text.isNotEmpty ? _skuController.text : '${widget.product.id}-$_selectedColorId-$_selectedRam-$_selectedStorage',
        'est_disponible': int.parse(_stockController.text) > 0,
      };

      if (_variantToEdit != null) {
        await AdminApiService.updateProductVariant(_variantToEdit!.id, variantData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variante modifiée avec succès!'), backgroundColor: Colors.green));
          // Update locally
          final index = widget.product.variantes.indexWhere((v) => v.id == _variantToEdit!.id);
          if (index != -1) {
            setState(() {
              widget.product.variantes[index] = ProductVariant(
                id: _variantToEdit!.id,
                prix: _prixController.text,
                prixInitial: _prixController.text,
                prixFinal: _prixController.text,
                enPromotion: _variantToEdit!.enPromotion,
                stock: int.parse(_stockController.text),
                estDisponible: int.parse(_stockController.text) > 0,
                desc: _variantToEdit!.desc, // Not fully accurate if they changed color/ram, but good enough without re-fetching
                couleurId: _selectedColorId,
                ram: _selectedRam,
                stockage: _selectedStorage,
                sku: _skuController.text,
              );
            });
          }
        }
      } else {
        await AdminApiService.createProductVariant(variantData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variante ajoutée avec succès!'), backgroundColor: Colors.green));
          Navigator.pop(context); // Return to list to see changes
        }
      }

      if (mounted && _variantToEdit != null) {
        _cancelEdit();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editVariant(ProductVariant variant) {
    setState(() {
      _variantToEdit = variant;
      _prixController.text = variant.prixInitial;
      _stockController.text = variant.stock.toString();
      _skuController.text = variant.sku ?? '';
      _selectedColorId = variant.couleurId;
      _selectedRam = variant.ram;
      _selectedStorage = variant.stockage;
    });
  }

  void _cancelEdit() {
    setState(() {
      _variantToEdit = null;
      _prixController.clear();
      _stockController.clear();
      _skuController.clear();
      _selectedColorId = null;
      _selectedRam = null;
      _selectedStorage = null;
    });
  }

  Future<void> _deleteVariant(int variantId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette variante ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminApiService.deleteProductVariant(variantId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variante supprimée')));
          // Remove variant from list locally to reflect changes without reloading from server immediately
          setState(() {
            widget.product.variantes.removeWhere((v) => v.id == variantId);
          });
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Variantes : ${widget.product.nomComplet}'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // List of existing variants
            const Text('Variantes existantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            widget.product.variantes.isEmpty 
              ? const Text('Aucune variante pour l\'instant.', style: TextStyle(color: Colors.grey))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.product.variantes.length,
                  itemBuilder: (context, index) {
                    final variant = widget.product.variantes[index];
                    return Card(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      child: ListTile(
                        title: Text(variant.desc, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        subtitle: Text('Prix: ${variant.prixInitial} F | Stock: ${variant.stock}', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editVariant(variant),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteVariant(variant.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            
            const Divider(height: 40, thickness: 2),
            
            // Add/Edit new variant form
            Text(_variantToEdit == null ? 'Ajouter une variante' : 'Modifier la variante', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_showsColor()) ...[
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Couleur'),
                      initialValue: _selectedColorId,
                      items: _colors.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['nom']))).toList(),
                      onChanged: (val) => setState(() => _selectedColorId = val),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  if (_showsRamAndStorage()) ...[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'RAM'),
                      initialValue: _selectedRam,
                      items: _rams.map((r) => DropdownMenuItem<String>(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => _selectedRam = val),
                    ),
                    const SizedBox(height: 12),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Stockage'),
                      initialValue: _selectedStorage,
                      items: _storages.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedStorage = val),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _prixController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Prix (F)'),
                          validator: (v) => v!.isEmpty ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stock initial'),
                          validator: (v) => v!.isEmpty ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(labelText: 'SKU (Optionnel - généré auto)'),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      if (_variantToEdit != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cancelEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Annuler', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      if (_variantToEdit != null) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? primaryColor : Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : Text(_variantToEdit == null ? 'Ajouter la variante' : 'Enregistrer', style: const TextStyle(fontSize: 16)),
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
