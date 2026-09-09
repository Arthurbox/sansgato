import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/admin_api_service.dart';

class VariantFormData {
  TextEditingController prixController = TextEditingController();
  TextEditingController stockController = TextEditingController();
  int? selectedColorId;
  String? selectedRam;
  String? selectedStockage;
  String? selectedTailleTv;
  String? selectedResolution;
  String? selectedTechnologie;
  String? selectedTauxRafraichissementTv;

  void dispose() {
    prixController.dispose();
    stockController.dispose();
  }
}

class AdminProductCreateScreen extends StatefulWidget {
  const AdminProductCreateScreen({super.key});

  @override
  State<AdminProductCreateScreen> createState() =>
      _AdminProductCreateScreenState();
}

class _AdminProductCreateScreenState extends State<AdminProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _modeleController = TextEditingController();
  final _descController = TextEditingController();

  // Computer specific controllers
  String? _selectedGeneration;
  final _customGenerationController = TextEditingController();
  final _frequenceController = TextEditingController();
  final _gpuController = TextEditingController();
  String? _selectedEcran;
  final _customEcranController = TextEditingController();
  String? _selectedTauxRafraichissement;
  final _customTauxRafraichissementController = TextEditingController();

  String? _selectedAccessoryType;
  final _customAccessoryTypeController = TextEditingController();

  String _etat = 'neuf'; // default
  int? _selectedCategoryId;
  int? _selectedBrandId;
  final _customBrandController = TextEditingController();

  // Variants list
  final List<VariantFormData> _variantes = [VariantFormData()];

  // Computer specific states
  String? _cpuBrand;
  String? _cpuModel;

  final List<XFile> _selectedImages = [];
  bool _isLoading = false;

  List<dynamic> _categories = [];
  List<dynamic> _brands = [];
  List<dynamic> _colors = [];

  final List<String> _ramChoices = [
    '4 GB',
    '6 GB',
    '8 GB',
    '12 GB',
    '16 GB',
    '24 GB',
    '32 GB',
  ];
  final List<String> _stockChoices = [
    '32 GB',
    '64 GB',
    '128 GB',
    '256 GB',
    '512 GB',
    '1 TB',
    '2 TB',
  ];

  final List<String> _intelModels = [
    'Core i3',
    'Core i5',
    'Core i7',
    'Core i9',
    'Core Ultra 3',
    'Core Ultra 5',
    'Core Ultra 7',
    'Core Ultra 9',
  ];
  final List<String> _amdModels = ['Ryzen 3', 'Ryzen 5', 'Ryzen 7', 'Ryzen 9'];
  final List<String> _generations = [
    '7ème',
    '8ème',
    '9ème',
    '10ème',
    '11ème',
    '12ème',
    '13ème',
    '14ème',
    '15ème',
    'Autre...',
  ];
  final List<String> _ecranChoices = [
    '11 pouces',
    '12 pouces',
    '13.3 pouces',
    '14 pouces',
    '15.6 pouces',
    '16 pouces',
    '17.3 pouces',
    '18 pouces',
    'Autre...',
  ];
  final List<String> _refreshRateChoices = [
    '60 Hz',
    '90 Hz',
    '120 Hz',
    '144 Hz',
    '165 Hz',
    '240 Hz',
    '300 Hz',
    '360 Hz',
    'Autre...',
  ];
  final List<String> _tailleTvChoices = [
    '24 pouces',
    '32 pouces',
    '40 pouces',
    '43 pouces',
    '50 pouces',
    '55 pouces',
    '65 pouces',
    '75 pouces',
    '85 pouces',
    '100 pouces',
    'Autre...',
  ];
  final List<String> _resolutionChoices = [
    'HD (1366x768)',
    'Full HD (1920x1080)',
    '4K Ultra HD (3840x2160)',
    '8K (7680x4320)',
  ];
  final List<String> _technologieChoices = [
    'LCD',
    'LED',
    'QLED',
    'OLED',
    'Mini-LED',
    'Micro-LED',
    'QD-Mini LED',
    'SQD-Mini LED',
  ];
  final List<String> _tauxRafraichissementTvChoices = [
    '50 Hz',
    '60 Hz',
    '100 Hz',
    '120 Hz',
    '144 Hz',
    '240 Hz',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _customGenerationController.dispose();
    _frequenceController.dispose();
    _gpuController.dispose();
    _customEcranController.dispose();
    _customTauxRafraichissementController.dispose();
    _customAccessoryTypeController.dispose();

    _customBrandController.dispose();
    for (var v in _variantes) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final cats = await AdminApiService.getCategories();
      final brands = await AdminApiService.getBrands();
      final colors = await AdminApiService.getColors();
      setState(() {
        _categories = cats;
        _brands = brands;
        _colors = colors;
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first['id'];
        }
        if (_isAccessory()) {
          _selectedBrandId = null;
        } else if (_brands.isNotEmpty) {
          _selectedBrandId = _brands.first['id'];
        }
        if (_colors.isNotEmpty) {
          _variantes.first.selectedColorId = _colors.first['id'];
        }
      });
    } catch (e) {
      debugPrint('Error loading data: ');
    }
  }

  bool _showsRamAndStorage() {
    if (_selectedCategoryId == null) return false;
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => null,
    );
    if (cat == null || cat['code'] == null) return false;
    final code = cat['code'].toString().toUpperCase();
    return code == 'SMARTPHONE' || code == 'TABLET' || code == 'COMPUTER';
  }

  bool _isComputer() {
    if (_selectedCategoryId == null) return false;
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => null,
    );
    if (cat == null || cat['code'] == null) return false;
    return cat['code'].toString().toUpperCase() == 'COMPUTER';
  }

  bool _isTelevision() {
    if (_selectedCategoryId == null) return false;
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => null,
    );
    if (cat == null || cat['code'] == null) return false;
    return cat['code'].toString().toUpperCase() == 'TV';
  }

  bool _isVentilator() {
    if (_selectedCategoryId == null) return false;
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => null,
    );
    if (cat == null || cat['nom'] == null) return false;
    return cat['nom'].toString().toUpperCase() == 'VENTILATEUR';
  }

  bool _isAccessory() {
    if (_selectedCategoryId == null) return false;
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => null,
    );
    if (cat == null) return false;
    final nom = cat['nom']?.toString().toUpperCase() ?? '';
    final code = cat['code']?.toString().toUpperCase() ?? '';
    return nom.contains('ACCESSOIRE') || code.contains('ACCESSOIRE');
  }

  bool _showsColor() {
    return !_isTelevision() && !_isVentilator();
  }

  void _addVariante() {
    setState(() {
      final newVar = VariantFormData();
      if (_colors.isNotEmpty) {
        newVar.selectedColorId = _colors.first['id'];
      }
      _variantes.add(newVar);
    });
  }

  void _removeVariante(int index) {
    if (_variantes.length > 1) {
      setState(() {
        _variantes[index].dispose();
        _variantes.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    // Validate variants
    for (int i = 0; i < _variantes.length; i++) {
      if (_variantes[i].prixController.text.isEmpty ||
          _variantes[i].stockController.text.isEmpty ||
          (_showsColor() && _variantes[i].selectedColorId == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prix, Stock et Couleur requis pour les variantes')),
        );
        return;
      }
    }

    if (_selectedBrandId == -1 && _customBrandController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom de la nouvelle marque'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int? finalBrandId = _selectedBrandId;
      if (_selectedBrandId == -1) {
        final newBrand = await AdminApiService.createBrand(
          _customBrandController.text,
          _selectedCategoryId!,
        );
        finalBrandId = newBrand['id'];
      }
      // Build Characteristics JSON
      Map<String, String> caracs = {};

      if (_isComputer()) {
        if (_cpuBrand != null) caracs['marque_processeur'] = _cpuBrand!;
        if (_cpuModel != null) caracs['modele_processeur'] = _cpuModel!;
        if (_selectedGeneration != null) {
          if (_selectedGeneration == 'Autre...' &&
              _customGenerationController.text.isNotEmpty) {
            caracs['generation'] = _customGenerationController.text;
          } else if (_selectedGeneration != 'Autre...') {
            caracs['generation'] = _selectedGeneration!;
          }
        }
        if (_frequenceController.text.isNotEmpty) {
          caracs['frequence'] = _frequenceController.text;
        }
        if (_gpuController.text.isNotEmpty) caracs['gpu'] = _gpuController.text;
        if (_selectedEcran != null) {
          if (_selectedEcran == 'Autre...' &&
              _customEcranController.text.isNotEmpty) {
            caracs['ecran'] = _customEcranController.text;
          } else if (_selectedEcran != 'Autre...') {
            caracs['ecran'] = _selectedEcran!;
          }
        }
        if (_selectedTauxRafraichissement != null) {
          if (_selectedTauxRafraichissement == 'Autre...' &&
              _customTauxRafraichissementController.text.isNotEmpty) {
            caracs['taux_rafraichissement'] =
                _customTauxRafraichissementController.text;
          } else if (_selectedTauxRafraichissement != 'Autre...') {
            caracs['taux_rafraichissement'] = _selectedTauxRafraichissement!;
          }
        }
      }

      if (_isAccessory()) {
        if (_selectedAccessoryType != null) {
          if (_selectedAccessoryType == 'Autre...' &&
              _customAccessoryTypeController.text.isNotEmpty) {
            caracs['type_accessoire'] = _customAccessoryTypeController.text;
          } else if (_selectedAccessoryType != 'Autre...') {
            caracs['type_accessoire'] = _selectedAccessoryType!;
          }
        }
      }

      // 1. Create base product
      final productData = {
        'nom_complet': _nomController.text,
        if (finalBrandId != null) 'marque': finalBrandId,
        'modele': _modeleController.text,
        'description': _descController.text,
        'etat': _etat,
        'categorie': _selectedCategoryId,
        'caracteristiques': caracs,
      };

      final createdProduct = await AdminApiService.createProduct(productData);
      final int productId = createdProduct['id'];

      // 2. Create variants
      int? firstVariantId;
      for (var v in _variantes) {
        final variantData = {
          'produit': productId,
          'couleur': v.selectedColorId,
          'prix': v.prixController.text,
          'stock': v.stockController.text.isNotEmpty ? v.stockController.text : 0,
        };

        if (_showsRamAndStorage()) {
          if (v.selectedRam != null) variantData['ram'] = v.selectedRam!;
          if (v.selectedStockage != null) {
            variantData['stockage'] = v.selectedStockage!;
          }
        }

        if (_isTelevision()) {
          if (v.selectedTailleTv != null && v.selectedTailleTv != 'Autre...') {
            variantData['taille_ecran'] = v.selectedTailleTv!;
          }
          if (v.selectedResolution != null) {
            final resMap = {
              'HD (1366x768)': 'hd',
              'Full HD (1920x1080)': 'full_hd',
              '4K Ultra HD (3840x2160)': '4k',
              '8K (7680x4320)': '8k',
            };
            variantData['resolution'] = resMap[v.selectedResolution!] ?? v.selectedResolution!;
          }
          if (v.selectedTechnologie != null) {
            final techMap = {
              'LCD': 'lcd',
              'LED': 'led',
              'QLED': 'qled',
              'OLED': 'oled',
              'Mini-LED': 'mini_led',
              'Micro-LED': 'micro_led',
              'QD-Mini LED': 'qd_mini_led',
              'SQD-Mini LED': 'sqd_mini_led',
            };
            variantData['technologie'] = techMap[v.selectedTechnologie!] ?? v.selectedTechnologie!;
          }
          if (v.selectedTauxRafraichissementTv != null) {
            final tauxMap = {
              '50 Hz': '50hz',
              '60 Hz': '60hz',
              '100 Hz': '100hz',
              '120 Hz': '120hz',
              '144 Hz': '144hz',
              '240 Hz': '240hz',
            };
            variantData['taux_rafraichissement'] = tauxMap[v.selectedTauxRafraichissementTv!] ?? v.selectedTauxRafraichissementTv!;
          }
        }

        final variantResult = await AdminApiService.createProductVariant(variantData);
        firstVariantId ??= variantResult['id'];
      }

      // 3. Upload images (attach them to the first variant)
      if (_selectedImages.isNotEmpty && firstVariantId != null) {
        for (final image in _selectedImages) {
          await AdminApiService.uploadVariantImage(firstVariantId, image);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit et variantes créés avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _selectedImages.addAll(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final showRamStorage = _showsRamAndStorage();
    final isComputer = _isComputer();
    final isAccessory = _isAccessory();

    List<String> cpuModels = [];
    if (_cpuBrand == 'Intel') cpuModels = _intelModels;
    if (_cpuBrand == 'AMD') cpuModels = _amdModels;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nouveau Produit'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- IMAGES ---
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Ajouter',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ..._selectedImages.map((image) {
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(image.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedImages.remove(image),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- PRODUIT BASE ---
                    const Text(
                      'Informations Générales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),

                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Catégorie *',
                      ),
                      initialValue: _selectedCategoryId,
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'],
                              child: Text(c['nom']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) async {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedBrandId = null;
                        });
                        try {
                          final filteredBrands =
                              await AdminApiService.getBrands(categoryId: val);
                          setState(() {
                            _brands = filteredBrands;
                            if (_isAccessory()) {
                              _selectedBrandId = null;
                            } else if (_brands.isNotEmpty) {
                              _selectedBrandId = _brands.first['id'];
                            }
                          });
                        } catch (e) {
                          debugPrint('Error loading filtered brands: $e');
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nomController,
                      decoration: InputDecoration(
                        labelText: isComputer
                            ? 'Nom complet (ex: HP EliteBook) *'
                            : 'Nom complet du produit *',
                        labelStyle: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: isAccessory ? 'Marque' : 'Marque *',
                            ),
                            initialValue: _selectedBrandId,
                            isExpanded: true,
                            items: [
                              if (isAccessory)
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text(
                                    'Défaut',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ..._brands
                                  .map(
                                    (b) => DropdownMenuItem<int>(
                                      value: b['id'],
                                      child: Text(b['nom']),
                                    ),
                                  )
                                  ,
                              const DropdownMenuItem<int>(
                                value: -1,
                                child: Text(
                                  'Autre (Ajouter...)',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedBrandId = val),
                            validator: (v) => (v == null && !isAccessory) ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _modeleController,
                            decoration: const InputDecoration(
                              labelText: 'Modèle *',
                            ),
                            validator: (v) => v!.isEmpty ? 'Requis' : null,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedBrandId == -1) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customBrandController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la nouvelle marque *',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    
                    if (isAccessory) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Type d\'accessoire *'),
                        initialValue: _selectedAccessoryType,
                        items: [
                          'Adaptateur secteur',
                          'Power Bank',
                          'Montre connectée',
                          'Souris',
                          'Clavier',
                          'Sacoche PC',
                          'Support téléphone',
                          'Carte mémoire',
                          'Clé USB',
                          'AirPods',
                          'Boîtier de charge',
                          'Casque Bluetooth',
                          'Casque filaire',
                          'Incassable',
                          'Fourreau',
                          'Boombox',
                          'Cable de charge',
                          'Support PC',
                          'Autre...'
                        ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _selectedAccessoryType = val),
                        validator: (v) => v == null ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      if (_selectedAccessoryType == 'Autre...') ...[
                        TextFormField(
                          controller: _customAccessoryTypeController,
                          decoration: const InputDecoration(labelText: 'Précisez le type d\'accessoire *'),
                          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'État du produit',
                      ),
                      initialValue: _etat,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'neuf', child: Text('Neuf')),
                        DropdownMenuItem(
                          value: 'occasion',
                          child: Text('Occasion'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _etat = val!),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // --- ORDINATEUR SPECIFICS ---
                    if (isComputer) ...[
                      const Text(
                        'Spécifications Ordinateur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Marque Processeur',
                                labelStyle: TextStyle(overflow: TextOverflow.ellipsis),
                              ),
                              initialValue: _cpuBrand,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Intel',
                                  child: Text('Intel'),
                                ),
                                DropdownMenuItem(
                                  value: 'AMD',
                                  child: Text('AMD'),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _cpuBrand = val;
                                  _cpuModel = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Modèle Processeur',
                              ),
                              initialValue: _cpuModel,
                              isExpanded: true,
                              items: cpuModels
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _cpuModel = val),
                              disabledHint: const Text(
                                'Sélectionnez la marque',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Génération',
                                  ),
                                  initialValue: _selectedGeneration,
                                  isExpanded: true,
                                  items: _generations
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(g),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedGeneration = val),
                                ),
                                if (_selectedGeneration == 'Autre...') ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _customGenerationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Précisez la génération',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _frequenceController,
                              decoration: const InputDecoration(
                                labelText: 'Fréquence (ex: 5.0 GHz)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gpuController,
                              decoration: const InputDecoration(
                                labelText: 'Carte Graphique (GPU)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Écran',
                                  ),
                                  initialValue: _selectedEcran,
                                  isExpanded: true,
                                  items: _ecranChoices
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedEcran = val),
                                ),
                                if (_selectedEcran == 'Autre...') ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _customEcranController,
                                    decoration: const InputDecoration(
                                      labelText: 'Précisez l\'écran',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Rafraîchissement',
                                  ),
                                  initialValue: _selectedTauxRafraichissement,
                                  isExpanded: true,
                                  items: _refreshRateChoices
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setState(
                                    () => _selectedTauxRafraichissement = val,
                                  ),
                                ),
                                if (_selectedTauxRafraichissement ==
                                    'Autre...') ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller:
                                        _customTauxRafraichissementController,
                                    decoration: const InputDecoration(
                                      labelText: 'Précisez le taux',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- VARIANTES DYNAMIQUES ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Variantes du Produit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addVariante,
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.deepPurple,
                          ),
                          label: const Text(
                            'Ajouter une variante',
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

                    ...List.generate(_variantes.length, (index) {
                      final v = _variantes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Variante ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  if (_variantes.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeVariante(index),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: v.prixController,
                                      decoration: const InputDecoration(
                                        labelText: 'Prix *',
                                        suffixText: 'F',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (val) =>
                                          val!.isEmpty ? 'Requis' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: v.stockController,
                                      decoration: const InputDecoration(
                                        labelText: 'Stock initial *',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (val) =>
                                          val!.isEmpty ? 'Requis' : null,
                                    ),
                                  ),
                                ],
                              ),
                              if (_showsColor()) ...[
                                const SizedBox(height: 12),
                                DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Couleur *',
                                  ),
                                  initialValue: v.selectedColorId,
                                  isExpanded: true,
                                  items: _colors
                                      .map(
                                        (c) => DropdownMenuItem<int>(
                                          value: c['id'],
                                          child: Text(c['nom']),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setState(
                                    () => v.selectedColorId = val,
                                  ),
                                  validator: (val) =>
                                      val == null ? 'Requis' : null,
                                ),
                              ],
                              if (showRamStorage) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'RAM',
                                        ),
                                        initialValue: v.selectedRam,
                                        isExpanded: true,
                                        items: _ramChoices
                                            .map(
                                              (r) => DropdownMenuItem(
                                                value: r,
                                                child: Text(r),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) =>
                                            setState(() => v.selectedRam = val),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Stockage',
                                        ),
                                        initialValue: v.selectedStockage,
                                        isExpanded: true,
                                        items: _stockChoices
                                            .map(
                                              (s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) => setState(
                                          () => v.selectedStockage = val,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (_isTelevision()) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Taille écran (TV) *',
                                          labelStyle: TextStyle(overflow: TextOverflow.ellipsis),
                                        ),
                                        initialValue: v.selectedTailleTv,
                                        isExpanded: true,
                                        items: _tailleTvChoices
                                            .map(
                                              (t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) => setState(
                                          () => v.selectedTailleTv = val,
                                        ),
                                        validator: (val) =>
                                            val == null ? 'Requis' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Résolution',
                                        ),
                                        initialValue: v.selectedResolution,
                                        isExpanded: true,
                                        items: _resolutionChoices
                                            .map(
                                              (r) => DropdownMenuItem(
                                                value: r,
                                                child: Text(r),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) => setState(
                                          () => v.selectedResolution = val,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Technologie',
                                        ),
                                        initialValue: v.selectedTechnologie,
                                        isExpanded: true,
                                        items: _technologieChoices
                                            .map(
                                              (t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) => setState(
                                          () => v.selectedTechnologie = val,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Taux de rafraîchissement',
                                        ),
                                        initialValue: v.selectedTauxRafraichissementTv,
                                        isExpanded: true,
                                        items: _tauxRafraichissementTvChoices
                                            .map(
                                              (t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) => setState(
                                          () => v.selectedTauxRafraichissementTv = val,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Créer le produit et ses variantes',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
