// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_element
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductVariant? _selectedVariant;
  double _swipePosition = 0.0;
  int _swipeState = 0; // 0: initial, 1: loading, 2: success
  int _currentImageIndex = 0;
  Product? _fullProduct; // Produit complet chargé depuis l'API (avec description)
  
  List<AvisClient> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    if (_product.variantes.isNotEmpty) {
      _selectedVariant = _product.variantes.firstWhere(
        (v) => v.images.isNotEmpty,
        orElse: () => _product.variantes.first,
      );
    }
    // Charger le détail complet depuis l'API pour avoir la description
    _loadFullProduct();
    _loadReviews();
  }
  
  Future<void> _loadReviews() async {
    try {
      final data = await ProductService.getProductReviews(widget.product.id);
      if (mounted) {
        setState(() {
          _reviews = (data['avis'] as List).map((v) => AvisClient.fromJson(v)).toList();
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _loadFullProduct() async {
    try {
      debugPrint('Product detail for: ${widget.product.id}');
      final full = await ProductService.getProductDetail(widget.product.id);
      if (mounted) {
        setState(() {
          _fullProduct = full;
          // Mettre à jour la variante sélectionnée si possible
          if (full.variantes.isNotEmpty) {
            _selectedVariant = full.variantes.firstWhere(
              (v) => v.images.isNotEmpty,
              orElse: () => full.variantes.first,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("ERREUR _loadFullProduct: $e");
      // Garde le produit minimal si l'API échoue
    }
  }

  Product get _product => _fullProduct ?? widget.product;

  List<String> get _uniqueStorages {
    return _product.variantes
        .where((v) => v.stockage != null && v.stockage!.isNotEmpty)
        .map((v) => v.stockage!)
        .toSet()
        .toList();
  }

  List<String> get _uniqueRams {
    return _product.variantes
        .where((v) => v.ram != null && v.ram!.isNotEmpty)
        .map((v) => v.ram!)
        .toSet()
        .toList();
  }

  List<String> get _uniqueTailleEcran {
    return _product.variantes
        .where((v) => v.tailleEcran != null && v.tailleEcran!.isNotEmpty)
        .map((v) => v.tailleEcran!)
        .toSet()
        .toList();
  }

  List<String> get _uniqueResolution {
    return _product.variantes
        .where((v) => v.resolution != null && v.resolution!.isNotEmpty)
        .map((v) => v.resolution!)
        .toSet()
        .toList();
  }

  List<String> get _uniqueTechnologie {
    return _product.variantes
        .where((v) => v.technologie != null && v.technologie!.isNotEmpty)
        .map((v) => v.technologie!)
        .toSet()
        .toList();
  }

  List<ProductVariant> get _uniqueColorVariants {
    final Map<int, ProductVariant> colorMap = {};
    for (var v in _product.variantes) {
      if (v.couleurId != null && !colorMap.containsKey(v.couleurId)) {
        colorMap[v.couleurId!] = v;
      }
    }
    return colorMap.values.toList();
  }

  void _onStorageSelected(String storage) {
    if (_selectedVariant == null) return;
    final currentColorId = _selectedVariant!.couleurId;
    final currentRam = _selectedVariant!.ram;
    ProductVariant? nextVariant = _product.variantes.cast<ProductVariant?>().firstWhere(
      (v) => v?.stockage == storage && v?.couleurId == currentColorId && v?.ram == currentRam,
      orElse: () => null,
    );
    nextVariant ??= _product.variantes.cast<ProductVariant?>().firstWhere(
      (v) => v?.stockage == storage && v?.couleurId == currentColorId,
      orElse: () => null,
    );
    nextVariant ??= _product.variantes.firstWhere(
      (v) => v.stockage == storage,
      orElse: () => _product.variantes.first,
    );
    setState(() {
      _selectedVariant = nextVariant;
    });
  }

  void _onColorSelected(int? colorId) {
    if (_selectedVariant == null || colorId == null) return;
    final currentStorage = _selectedVariant!.stockage;
    final currentRam = _selectedVariant!.ram;
    ProductVariant? nextVariant = _product.variantes.cast<ProductVariant?>().firstWhere(
      (v) => v?.couleurId == colorId && v?.stockage == currentStorage && v?.ram == currentRam,
      orElse: () => null,
    );
    nextVariant ??= _product.variantes.cast<ProductVariant?>().firstWhere(
      (v) => v?.couleurId == colorId && v?.stockage == currentStorage,
      orElse: () => null,
    );
    nextVariant ??= _product.variantes.firstWhere(
      (v) => v.couleurId == colorId,
      orElse: () => _product.variantes.first,
    );
    setState(() {
      _selectedVariant = nextVariant;
    });
  }

  void _onRamSelected(String ram) {
    if (_selectedVariant == null) return;
    final currentColorId = _selectedVariant!.couleurId;
    final currentStorage = _selectedVariant!.stockage;
    ProductVariant? nextVariant = _product.variantes.cast<ProductVariant?>().firstWhere(
      (v) => v?.ram == ram && v?.couleurId == currentColorId && v?.stockage == currentStorage,
      orElse: () => null,
    );
    nextVariant ??= _product.variantes.cast<ProductVariant?>().firstWhere(
      (v) => v?.ram == ram && v?.couleurId == currentColorId,
      orElse: () => null,
    );
    nextVariant ??= _product.variantes.firstWhere(
      (v) => v.ram == ram,
      orElse: () => _product.variantes.first,
    );
    setState(() {
      _selectedVariant = nextVariant;
    });
  }

  void _onGenericTvSelected({String? taille, String? res, String? tech}) {
    if (_selectedVariant == null) return;
    final targetTaille = taille ?? _selectedVariant!.tailleEcran;
    final targetRes = res ?? _selectedVariant!.resolution;
    final targetTech = tech ?? _selectedVariant!.technologie;
    final currentColorId = _selectedVariant!.couleurId;

    ProductVariant? nextVariant = _product.variantes.cast<ProductVariant?>().firstWhere(
      (v) => v?.tailleEcran == targetTaille && v?.resolution == targetRes && v?.technologie == targetTech && v?.couleurId == currentColorId,
      orElse: () => null,
    );
    nextVariant ??= _product.variantes.cast<ProductVariant?>().firstWhere(
      (v) => v?.tailleEcran == targetTaille && v?.resolution == targetRes && v?.technologie == targetTech,
      orElse: () => null,
    );
    nextVariant ??= _product.variantes.cast<ProductVariant?>().firstWhere(
      (v) => v?.tailleEcran == targetTaille,
      orElse: () => null,
    );
    nextVariant ??= _product.variantes.firstWhere(
      (v) => true,
      orElse: () => _product.variantes.first,
    );
    setState(() {
      _selectedVariant = nextVariant;
    });
  }

  void _handleSwipe(DragUpdateDetails details, double maxWidth) {
    if (_swipeState != 0) return;
    setState(() {
      _swipePosition += details.delta.dx;
      if (_swipePosition < 0) _swipePosition = 0;
      if (_swipePosition > maxWidth - 52) _swipePosition = maxWidth - 52; // 52 is button width
    });
  }

  void _handleSwipeEnd(DragEndDetails details, double maxWidth) {
    if (_swipeState != 0) return;
    if (_swipePosition > (maxWidth - 52) * 0.7) { // 70% swiped
      setState(() {
        _swipePosition = maxWidth - 52;
        _swipeState = 1;
      });
      _addToCart();
    } else {
      setState(() {
        _swipePosition = 0;
      });
    }
  }

  void _addToCart() async {
    if (_selectedVariant == null) {
      if (mounted) {
        setState(() { _swipeState = 0; _swipePosition = 0; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une variante.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    // Appel API réel via le provider
    final error = await ref.read(cartProvider.notifier).addItem(
      contentType: 'productvariant',
      objectId: _selectedVariant!.id,
      quantite: 1,
    );

    if (!mounted) return;

    if (error == null) {
      setState(() { _swipeState = 2; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_product.nomComplet} ajouté au panier !'),
          backgroundColor: const Color(0xFF00A9C1),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } else {
      setState(() { _swipeState = 0; _swipePosition = 0; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() { _swipeState = 0; _swipePosition = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);
    final bgColor = isDark ? Colors.grey[900]! : const Color(0xFFF7F9FC);
    final textColor = isDark ? Colors.white : Colors.black87;

    // Images: use current variant's images first.
    // If none, search all other variants for an image (fallback).
    List<ProductImage> activeImages = [];
    if (_selectedVariant != null && _selectedVariant!.images.isNotEmpty) {
      activeImages = _selectedVariant!.images;
    } else {
      for (var v in _product.variantes) {
        if (v.images.isNotEmpty) {
          activeImages = v.images;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      color: textColor,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    _product.categorie?.nom ?? _product.marque,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                          color: textColor,
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
                              top: 4,
                              right: 4,
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
                  ),
                ],
              ),
            ),

            // Main body
            Expanded(
              child: Stack(
                children: [
                  // Floating Image
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 65.0, right: 40.0), // Image élargie sans toucher les bords
                          child: SizedBox(
                            height: 340, // Augmenté en hauteur
                            child: activeImages.isNotEmpty
                                ? PageView.builder(
                                    itemCount: activeImages.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      final img = activeImages[index].image;
                                      final imgUrl = img.startsWith('http') ? img : '${AuthService.baseUrl}$img';
                                      return CachedNetworkImage(
                                        imageUrl: imgUrl,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                      );
                                    },
                                  )
                                : Icon(Icons.inventory, size: 180, color: Colors.grey.shade400),
                          ),
                        ),
                        if (activeImages.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(activeImages.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  width: _currentImageIndex == index ? 10.0 : 6.0,
                                  height: 6.0,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index ? primaryColor : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(3.0),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Left column (Sizes/Storage/TV Specs)
                  Positioned(
                    left: 4,
                    top: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_product.categorie?.code == 'TV') ...[
                          if (_uniqueTailleEcran.isNotEmpty) ...[
                            Text('Taille', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor)),
                            const SizedBox(height: 4),
                            ..._uniqueTailleEcran.map((taille) {
                              bool isSel = _selectedVariant?.tailleEcran == taille;
                              return GestureDetector(
                                onTap: () => _onGenericTvSelected(taille: taille),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel ? textColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSel ? textColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                                  ),
                                  child: Text(
                                    taille,
                                    style: TextStyle(
                                      color: isSel ? bgColor : textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                          ],
                          if (_uniqueResolution.isNotEmpty) ...[
                            Text('Résolution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor)),
                            const SizedBox(height: 4),
                            ..._uniqueResolution.map((res) {
                              bool isSel = _selectedVariant?.resolution == res;
                              return GestureDetector(
                                onTap: () => _onGenericTvSelected(res: res),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel ? textColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSel ? textColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                                  ),
                                  child: Text(
                                    res,
                                    style: TextStyle(
                                      color: isSel ? bgColor : textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                          ],
                          if (_uniqueTechnologie.isNotEmpty) ...[
                            Text('Technologie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor)),
                            const SizedBox(height: 4),
                            ..._uniqueTechnologie.map((tech) {
                              bool isSel = _selectedVariant?.technologie == tech;
                              return GestureDetector(
                                onTap: () => _onGenericTvSelected(tech: tech),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel ? textColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSel ? textColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                                  ),
                                  child: Text(
                                    tech,
                                    style: TextStyle(
                                      color: isSel ? bgColor : textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ] else ...[
                          if (_uniqueStorages.isNotEmpty) ...[
                            Text('Stockages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor)),
                            const SizedBox(height: 4),
                            ..._uniqueStorages.map((storage) {
                              bool isSel = _selectedVariant?.stockage == storage;
                              return GestureDetector(
                                onTap: () => _onStorageSelected(storage),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel ? textColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSel ? textColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                                  ),
                                  child: Text(
                                    storage,
                                    style: TextStyle(
                                      color: isSel ? bgColor : textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                          ],
                          if (_uniqueRams.isNotEmpty) ...[
                            Text('RAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor)),
                            const SizedBox(height: 4),
                            ..._uniqueRams.map((ram) {
                              bool isSel = _selectedVariant?.ram == ram;
                              return GestureDetector(
                                onTap: () => _onRamSelected(ram),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel ? textColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSel ? textColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                                  ),
                                  child: Text(
                                    ram,
                                    style: TextStyle(
                                      color: isSel ? bgColor : textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ],
                    ),
                  ),

                  // Right column (Actions + Colors)
                  Positioned(
                    right: 4,
                    top: 10,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Icon(Icons.favorite_border, color: Colors.red, size: 18),
                        ),
                        const SizedBox(height: 12),
                        // Couleurs dynamiques (non affichées pour les télévisions)
                        if (_product.categorie?.code != 'TV')
                          ..._uniqueColorVariants.map((v) {
                            bool isSel = _selectedVariant?.couleurId == v.couleurId;
                            Color parsedColor = Colors.grey;
                            if (v.couleurHex != null) {
                              String hex = v.couleurHex!.replaceAll('#', '');
                              if (hex.length == 6) hex = 'FF$hex';
                              parsedColor = Color(int.parse(hex, radix: 16));
                            }
                            return GestureDetector(
                              onTap: () => _onColorSelected(v.couleurId),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: parsedColor,
                                  border: Border.all(
                                    color: isSel ? primaryColor : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  // Middle Description
                  if (_product.description != null && _product.description!.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: _product.categorie?.code == 'TV' ? 100.0 : 80.0,
                      right: 55,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _product.description!,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            height: 1.3,
                          ),
                          maxLines: 12,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Panel (Cyan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.nomComplet,
                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _showReviewsSheet,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.star, color: Colors.orangeAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_product.noteMoyenne > 0 ? _product.noteMoyenne.toStringAsFixed(1) : "N/A"} (${_product.avisCount})', 
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        Text('Prix', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _selectedVariant != null ? _selectedVariant!.prixFinal : '-',
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4.0),
                              child: Text('CFA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Swipe to Add Button
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final isInitial = _swipeState == 0;
                      final isLoading = _swipeState == 1;
                      final isSuccess = _swipeState == 2;
                      
                      final buttonWidth = isInitial ? maxWidth : 52.0;
                      final bgColorContainer = isSuccess 
                          ? Colors.green 
                          : (isDark ? Colors.grey.shade800 : Colors.white);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: buttonWidth,
                        height: 52,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: bgColorContainer,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: isInitial 
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Effet de remplissage coloré pendant le glissement
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: _swipePosition + 52,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                    ),
                                  ),
                                  OverflowBox(
                                    maxWidth: maxWidth,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Glisser pour ajouter au panier  ',
                                          style: TextStyle(color: isDark ? Colors.white : Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        Icon(Icons.keyboard_double_arrow_right, color: isDark ? Colors.white54 : Colors.grey.shade500, size: 16),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: _swipePosition,
                                    child: GestureDetector(
                                      onPanUpdate: (details) => _handleSwipe(details, maxWidth),
                                      onPanEnd: (details) => _handleSwipeEnd(details, maxWidth),
                                      child: Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(26),
                                        ),
                                        child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check, color: Colors.white, size: 28),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
            final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Avis clients (${_product.avisCount})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddReviewDialog();
                        },
                        icon: const Icon(Icons.edit, size: 16, color: Color(0xFF00A9C1)),
                        label: const Text('Donner un avis', style: TextStyle(color: Color(0xFF00A9C1))),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoadingReviews 
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A9C1)))
                      : _reviews.isEmpty
                        ? Center(child: Text('Aucun avis pour l\'instant.', style: TextStyle(color: subColor)))
                        : ListView.separated(
                            controller: controller,
                            itemCount: _reviews.length,
                            separatorBuilder: (_, __) => Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(review.userName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                        Row(
                                          children: List.generate(5, (i) => Icon(
                                            i < review.note ? Icons.star : Icons.star_border,
                                            size: 14,
                                            color: Colors.orangeAccent,
                                          )),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(review.commentaire, style: TextStyle(color: subColor, fontSize: 13, height: 1.4)),
                                    const SizedBox(height: 4),
                                    Text(review.createdAt.substring(0, 10), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  void _showAddReviewDialog() {
    int selectedNote = 5;
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Votre avis'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedNote ? Icons.star : Icons.star_border,
                          color: Colors.orangeAccent,
                          size: 32,
                        ),
                        onPressed: () => setDialogState(() => selectedNote = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Qu\'avez-vous pensé de ce produit ?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A9C1)),
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    
                    try {
                      await ProductService.addProductReview(
                        widget.product.id,
                        selectedNote,
                        commentController.text.trim(),
                      );
                      _loadFullProduct();
                      _loadReviews();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Merci pour votre avis !'),
                        backgroundColor: Colors.green,
                      ));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString().contains('déjà donné') ? 'Vous avez déjà donné un avis.' : 'Erreur lors de l\'envoi.'),
                        backgroundColor: Colors.redAccent,
                      ));
                    }
                  },
                  child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    );
  }
}
