import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/admin_api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminProductWizardScreen extends StatefulWidget {
  const AdminProductWizardScreen({super.key});

  @override
  State<AdminProductWizardScreen> createState() => _AdminProductWizardScreenState();
}

class _AdminProductWizardScreenState extends State<AdminProductWizardScreen> {
  int _currentStep = 0;
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  List<dynamic> _categories = [];
  List<dynamic> _brands = [];
  List<dynamic> _colors = [];

  // --- Step 1 Data ---
  final _formKeyStep1 = GlobalKey<FormState>();
  int? _selectedCategory;
  int? _selectedBrand;
  String _modele = '';
  String _nomComplet = '';
  String _description = '';
  String _etat = 'neuf'; 

  // --- Step 2 Data (Variants) ---
  final _formKeyStep2 = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _variants = [];

  // --- Step 3 Data (Images) ---
  // Keyed by variant index, value is list of XFile
  final Map<int, List<XFile>> _variantImages = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final cats = await AdminApiService.getCategories();
      final brnds = await AdminApiService.getBrands();
      final cols = await AdminApiService.getColors();
      setState(() {
        _categories = cats;
        _brands = brnds;
        _colors = cols;
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'couleur': null,
        'ram': null,
        'stockage': null,
        'prix_achat': '0',
        'prix': '0',
        'stock': '0',
      });
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
      _variantImages.remove(index);
    });
  }

  Future<void> _pickImageForVariant(int index) async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _variantImages[index] = (_variantImages[index] ?? [])..addAll(images);
      });
    }
  }

  void _removeImageForVariant(int variantIndex, int imageIndex) {
    setState(() {
      _variantImages[variantIndex]?.removeAt(imageIndex);
    });
  }

  Future<void> _submitProduct(String statutPublication) async {
    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez ajouter au moins une variante.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final productData = {
        'categorie': _selectedCategory,
        'marque': _selectedBrand,
        'modele': _modele,
        'nom_complet': _nomComplet,
        'description': _description,
        'etat': _etat,
        'statut_publication': statutPublication,
        'caracteristiques': {}, 
      };

      // 1. Créer le produit
      final product = await AdminApiService.createProduct(productData);
      final int productId = product['id'];

      // 2. Créer les variantes
      for (int i = 0; i < _variants.length; i++) {
        var v = _variants[i];
        final variantData = {
          'produit': productId,
          'couleur': v['couleur'],
          'ram': v['ram'],
          'stockage': v['stockage'],
          'prix_achat': double.tryParse(v['prix_achat'].toString()) ?? 0,
          'prix': double.tryParse(v['prix'].toString()) ?? 0,
          'stock': int.tryParse(v['stock'].toString()) ?? 0,
        };

        final variant = await AdminApiService.createProductVariant(variantData);
        final int variantId = variant['id'];

        // 3. Uploader les images pour cette variante
        if (_variantImages.containsKey(i) && _variantImages[i]!.isNotEmpty) {
          for (var imageFile in _variantImages[i]!) {
            await AdminApiService.uploadVariantImage(variantId, imageFile);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Produit créé avec succès !'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la création: $e'),
          backgroundColor: Colors.red,
        ));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nouveau Produit')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Création de Produit')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_formKeyStep1.currentState!.validate()) {
              _formKeyStep1.currentState!.save();
              setState(() => _currentStep += 1);
            }
          } else if (_currentStep == 1) {
            if (_formKeyStep2.currentState!.validate()) {
              _formKeyStep2.currentState!.save();
              setState(() => _currentStep += 1);
            }
          } else if (_currentStep == 2) {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          if (_currentStep == 3) {
            return const SizedBox.shrink(); // Hide default controls on last step
          }
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Suivant'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: Text(_currentStep == 0 ? 'Annuler' : 'Précédent'),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          _buildStep1Infos(),
          _buildStep2Variants(),
          _buildStep3Images(),
          _buildStep4Publication(),
        ],
      ),
    );
  }

  Step _buildStep1Infos() {
    return Step(
      title: const Text('Infos'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _formKeyStep1,
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Catégorie'),
              initialValue: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem<int>(
                value: c['id'],
                child: Text(c['nom']),
              )).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              validator: (val) => val == null ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Marque'),
              initialValue: _selectedBrand,
              items: _brands.map((b) => DropdownMenuItem<int>(
                value: b['id'],
                child: Text(b['nom']),
              )).toList(),
              onChanged: (val) => setState(() => _selectedBrand = val),
              validator: (val) => val == null ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Modèle (ex: Galaxy S24)'),
              onSaved: (val) => _modele = val ?? '',
              validator: (val) => val!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nom Complet (ex: Samsung Galaxy S24 5G)'),
              onSaved: (val) => _nomComplet = val ?? '',
              validator: (val) => val!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'État'),
              initialValue: _etat,
              items: const [
                DropdownMenuItem(value: 'neuf', child: Text('Neuf')),
                DropdownMenuItem(value: 'occasion', child: Text('Occasion')),
              ],
              onChanged: (val) => setState(() => _etat = val!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description commerciale'),
              maxLines: 4,
              onSaved: (val) => _description = val ?? '',
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep2Variants() {
    return Step(
      title: const Text('Variantes'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _formKeyStep2,
        child: Column(
          children: [
            if (_variants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Créez la première variante de votre produit (ex: 256Go Noir).'),
              ),
            ..._variants.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> variant = entry.value;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Variante #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeVariant(index),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(labelText: 'Couleur'),
                              initialValue: variant['couleur'],
                              items: _colors.map((c) => DropdownMenuItem<int>(
                                value: c['id'],
                                child: Text(c['nom']),
                              )).toList(),
                              onChanged: (val) => setState(() => _variants[index]['couleur'] = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'RAM'),
                              initialValue: variant['ram'],
                              items: ['4 GB', '6 GB', '8 GB', '12 GB', '16 GB', '24 GB'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                              onChanged: (val) => setState(() => _variants[index]['ram'] = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Stockage'),
                        initialValue: variant['stockage'],
                        items: ['64 GB', '128 GB', '256 GB', '512 GB', '1 TB'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _variants[index]['stockage'] = val),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Prix (Vente)', suffixText: 'F'),
                              keyboardType: TextInputType.number,
                              initialValue: variant['prix'],
                              onSaved: (val) => _variants[index]['prix'] = val,
                              validator: (val) => val!.isEmpty ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Prix (Achat)', suffixText: 'F'),
                              keyboardType: TextInputType.number,
                              initialValue: variant['prix_achat'],
                              onSaved: (val) => _variants[index]['prix_achat'] = val,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Stock Initial'),
                        keyboardType: TextInputType.number,
                        initialValue: variant['stock'],
                        onSaved: (val) => _variants[index]['stock'] = val,
                        validator: (val) => val!.isEmpty ? 'Requis' : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une variante'),
              onPressed: _addVariant,
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep3Images() {
    return Step(
      title: const Text('Images'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ajoutez des images pour chaque variante.', style: TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          if (_variants.isEmpty)
            const Text('Veuillez d\'abord créer des variantes à l\'étape précédente.'),
          ..._variants.asMap().entries.map((entry) {
            int index = entry.key;
            final images = _variantImages[index] ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Variante #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...images.asMap().entries.map((imgEntry) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? CachedNetworkImage(imageUrl: imgEntry.value.path, width: 80,
                                        height: 80,
                                        fit: BoxFit.cover, placeholder: (context, url) => const Center(child: CircularProgressIndicator()), errorWidget: (context, url, error) => const Icon(Icons.error))
                                    : Image.file(
                                        File(imgEntry.value.path),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _removeImageForVariant(index, imgEntry.key),
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              )
                            ],
                          );
                        }),
                        GestureDetector(
                          onTap: () => _pickImageForVariant(index),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Icon(Icons.add_a_photo, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Step _buildStep4Publication() {
    return Step(
      title: const Text('Publier'),
      isActive: _currentStep >= 3,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Récapitulatif final', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Modèle : $_modele'),
          Text('Nombre de variantes : ${_variants.length}'),
          const SizedBox(height: 24),
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator())
          else ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
              icon: const Icon(Icons.publish, color: Colors.white),
              label: const Text('Publier Maintenant', style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () => _submitProduct('publie'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
              icon: const Icon(Icons.drafts, color: Colors.white),
              label: const Text('Enregistrer comme Brouillon', style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () => _submitProduct('brouillon'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              icon: const Icon(Icons.archive),
              label: const Text('Archiver', style: TextStyle(fontSize: 16)),
              onPressed: () => _submitProduct('archive'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => setState(() => _currentStep -= 1),
              child: const Text('Retour aux images'),
            )
          ]
        ],
      ),
    );
  }
}
