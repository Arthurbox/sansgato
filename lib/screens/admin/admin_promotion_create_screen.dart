import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../models/kit.dart';

class AdminPromotionCreateScreen extends StatefulWidget {
  final Map<String, dynamic>? promoToEdit;
  const AdminPromotionCreateScreen({super.key, this.promoToEdit});

  @override
  State<AdminPromotionCreateScreen> createState() => _AdminPromotionCreateScreenState();
}

class _AdminPromotionCreateScreenState extends State<AdminPromotionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  
  String _selectedTargetType = 'productvariant';
  ProductVariant? _selectedVariant;
  Kit? _selectedKit;
  
  String _typeReduction = 'pourcentage';
  final _valeurController = TextEditingController();
  
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 7));

  List<Product> _products = [];
  List<ProductVariant> _allVariants = [];
  List<Kit> _kits = [];

  @override
  void initState() {
    super.initState();
    if (widget.promoToEdit != null) {
      _selectedTargetType = widget.promoToEdit!['content_type_model'] ?? 'productvariant';
      _typeReduction = widget.promoToEdit!['type_reduction'] ?? 'pourcentage';
      _valeurController.text = widget.promoToEdit!['valeur'].toString();
      if (widget.promoToEdit!['date_debut'] != null) {
        _dateDebut = DateTime.parse(widget.promoToEdit!['date_debut']);
      }
      if (widget.promoToEdit!['date_fin'] != null) {
        _dateFin = DateTime.parse(widget.promoToEdit!['date_fin']);
      }
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await ProductService.getProducts();
      List<ProductVariant> variants = [];
      for (var p in products) {
        variants.addAll(p.variantes);
      }
      final kits = await ProductService.getKits();
      
      setState(() {
        _products = products;
        _allVariants = variants;
        _kits = kits;
        
        if (widget.promoToEdit != null) {
          final targetId = widget.promoToEdit!['object_id'];
          if (_selectedTargetType == 'productvariant') {
            try {
              _selectedVariant = _allVariants.firstWhere((v) => v.id == targetId);
            } catch (e) {}
          } else if (_selectedTargetType == 'kit') {
            try {
              _selectedKit = _kits.firstWhere((k) => k.id == targetId);
            } catch (e) {}
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading data for promotion: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final initialDate = isDebut ? _dateDebut : _dateFin;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
          if (_dateFin.isBefore(_dateDebut)) {
            _dateFin = _dateDebut.add(const Duration(days: 1));
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTargetType == 'productvariant' && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une variante')));
      return;
    }
    if (_selectedTargetType == 'kit' && _selectedKit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un kit')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final promoData = {
        'content_type': _selectedTargetType == 'productvariant' ? 12 : 14, // NOTE: Ces IDs doivent correspondre aux IDs des ContentTypes du backend. En general, mieux vaut utiliser des champs dédiés ou un endpoint backend qui gère cela. Mais on va utiliser les ids par défaut Django si possible, sinon le backend doit accepter des chaînes, mais on a configuré le backend pour `content_type` qui attend un ID de table Django ContentType.
        // Wait, on the backend we added `AdminPromotionSerializer` which might expect an integer for `content_type`.
      };
      // Correction: L'API attend l'ID du content_type. Pour éviter les erreurs d'ID de table, on va envoyer un payload adapté au backend.
      // Modifions le payload
      final payload = {
        'content_type_model': _selectedTargetType,
        'object_id': _selectedTargetType == 'productvariant' ? _selectedVariant!.id : _selectedKit!.id,
        'type_reduction': _typeReduction,
        'valeur': double.parse(_valeurController.text),
        'date_debut': _dateDebut.toIso8601String(),
        'date_fin': _dateFin.toIso8601String(),
        'statut': true,
      };

      if (widget.promoToEdit != null) {
        await AdminApiService.updatePromotion(widget.promoToEdit!['id'], payload);
      } else {
        await AdminApiService.createPromotion(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.promoToEdit != null ? 'Promotion mise à jour avec succès!' : 'Promotion créée avec succès!'),
            backgroundColor: Colors.green
          )
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.promoToEdit != null ? 'Modifier Promotion' : 'Nouvelle Promotion'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _products.isEmpty && _kits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Type de cible'),
                      initialValue: _selectedTargetType,
                      items: const [
                        DropdownMenuItem(value: 'productvariant', child: Text('Variante de Produit')),
                        DropdownMenuItem(value: 'kit', child: Text('Kit')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedTargetType = val!;
                          _selectedVariant = null;
                          _selectedKit = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedTargetType == 'productvariant')
                      DropdownButtonFormField<ProductVariant>(
                        decoration: const InputDecoration(labelText: 'Variante à promouvoir'),
                        isExpanded: true,
                        initialValue: _selectedVariant,
                        items: _allVariants.map((v) => DropdownMenuItem(value: v, child: Text('${v.desc} (ID: ${v.id})'))).toList(),
                        onChanged: (val) => setState(() => _selectedVariant = val),
                      )
                    else
                      DropdownButtonFormField<Kit>(
                        decoration: const InputDecoration(labelText: 'Kit à promouvoir'),
                        isExpanded: true,
                        initialValue: _selectedKit,
                        items: _kits.map((k) => DropdownMenuItem(value: k, child: Text(k.nom))).toList(),
                        onChanged: (val) => setState(() => _selectedKit = val),
                      ),
                    
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Type de réduction'),
                      initialValue: _typeReduction,
                      items: const [
                        DropdownMenuItem(value: 'pourcentage', child: Text('Pourcentage (%)')),
                        DropdownMenuItem(value: 'montant', child: Text('Montant fixe (F)')),
                      ],
                      onChanged: (val) => setState(() => _typeReduction = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valeurController,
                      decoration: InputDecoration(labelText: 'Valeur de la réduction ${_typeReduction == 'pourcentage' ? '(%)' : '(F)'}'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Date de début', border: OutlineInputBorder()),
                              child: Text('${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Date de fin', border: OutlineInputBorder()),
                              child: Text('${_dateFin.day}/${_dateFin.month}/${_dateFin.year}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? primaryColor : Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(widget.promoToEdit != null ? 'Enregistrer' : 'Créer la Promotion', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
