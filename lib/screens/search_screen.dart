import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/auth_service.dart';
import 'product_detail_screen.dart';
import '../providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Category> _categories = [];
  int? _selectedCategoryId;
  
  List<Product> _results = [];
  bool _isLoading = false;
  String? _error;
  
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService.getCategories();
      if (mounted) setState(() { _categories = cats; });
    } catch (e) {
      debugPrint('Erreur catégories: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }
  
  void _selectCategory(int? catId) {
    setState(() {
      _selectedCategoryId = catId;
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategoryId == null) {
      setState(() {
        _results = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      final products = await ProductService.getProducts(
        search: query.isNotEmpty ? query : null,
        categoryId: _selectedCategoryId,
      );
      if (mounted) setState(() { _results = products; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _formatPrice(String rawPrice) {
    try {
      final value = double.parse(rawPrice);
      final intValue = value.round();
      final formatted = intValue.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
      return '$formatted F';
    } catch (_) {
      return '$rawPrice F';
    }
  }

  String _firstImageUrl(Product product) {
    for (final v in product.variantes) {
      if (v.images.isNotEmpty) return v.images.first.image;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit...',
                    hintStyle: TextStyle(color: subColor),
                    prefixIcon: Icon(Icons.search, color: subColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: subColor),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
            
            // Categories Filter
            if (_categories.isNotEmpty)
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == _categories[index - 1].id;
                    final label = isAll ? 'Tout' : _categories[index - 1].nom;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          _selectCategory(isAll ? null : _categories[index - 1].id);
                        },
                        selectedColor: const Color(0xFF00A9C1),
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  },
                ),
              ),

            // Results Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A9C1)))
                  : _error != null
                      ? _buildError()
                      : (_results.isEmpty && (_searchController.text.isNotEmpty || _selectedCategoryId != null))
                          ? _buildEmpty(isDark, subColor)
                          : (_results.isEmpty)
                              ? _buildInitialState(subColor)
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.65,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: _results.length,
                                  itemBuilder: (context, index) {
                                    return _buildProductCard(_results[index], isDark, cardColor, textColor, subColor);
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isDark, Color cardColor, Color textColor, Color subColor) {
    final imageUrl = _firstImageUrl(product);
    final variant = product.variantes.isNotEmpty ? product.variantes.first : null;

    final cartAsync = ref.watch(cartProvider);
    bool isAdded = false;
    if (variant != null && cartAsync.value != null) {
      for (var item in cartAsync.value!.items) {
        if (item.itemType == 'productvariant' && item.item.id == variant.id) {
          isAdded = true;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(imageUrl: imageUrl.startsWith('http') ? imageUrl : '${AuthService.baseUrl}$imageUrl', fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()), errorWidget: (context, url, error) => const Icon(Icons.error))
                    : _imagePlaceholder(isDark),
              ),
            ),
            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nomComplet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    if (variant != null) ...[
                      if (variant.enPromotion)
                        Text(
                          _formatPrice(variant.prixInitial),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _formatPrice(variant.prixFinal),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: variant.enPromotion ? Colors.red : textColor,
                              ),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: isAdded ? null : () async {
                              final error = await ref.read(cartProvider.notifier).addItem(
                                contentType: 'productvariant',
                                objectId: variant.id,
                                quantite: 1,
                              );
                              if (error == null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.nomComplet} ajouté !'),
                                    backgroundColor: const Color(0xFF00A9C1),
                                    duration: const Duration(milliseconds: 1500),
                                  ),
                                );
                              } else if (error != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAdded ? null : (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A)),
                                gradient: isAdded
                                    ? const LinearGradient(
                                        colors: [Color(0xFF00A9C1), Color(0xFF00899D)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAdded ? const Color(0xFF00A9C1) : Colors.black).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isAdded ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                                color: isAdded ? Colors.white : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color subColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 72, color: subColor.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: subColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez d\'autres mots-clés ou catégories.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInitialState(Color subColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search, size: 72, color: subColor.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Que recherchez-vous ?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: subColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Tapez votre recherche ci-dessus.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('Erreur de recherche', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _performSearch,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A9C1)),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
      child: Icon(Icons.image_outlined, size: 40, color: isDark ? Colors.grey[700] : Colors.grey[400]),
    );
  }
}
