// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_element
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_api_service.dart';
import '../../models/product.dart';
import '../../utils/responsive.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final int _refreshKey = 0;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = AdminApiService.getProducts();
    });
  }

  void _showAdjustStockDialog(int varianteId, String varianteNom, int currentStock) {
    final qtyController = TextEditingController();
    final motifController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajuster le stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Variante: $varianteNom', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Stock actuel: $currentStock'),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Quantité à ajouter/retirer',
                  hintText: 'Ex: 10 pour ajouter, -5 pour retirer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motifController,
                decoration: const InputDecoration(
                  labelText: 'Motif (Optionnel)',
                  hintText: 'Ex: Réassort, Perte...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qtyStr = qtyController.text.trim();
                final qty = int.tryParse(qtyStr);
                final motif = motifController.text.trim().isEmpty ? 'Ajustement manuel' : motifController.text.trim();

                if (qty == null || qty == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer une quantité valide')));
                  return;
                }

                Navigator.pop(context); // close dialog
                
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                
                try {
                  await AdminApiService.adjustStock(varianteId, qty, motif);
                  if (!mounted) return;
                  Navigator.pop(context); // close loading
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock mis à jour avec succès'), backgroundColor: Colors.green));
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le produit a été mis à jour.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Valider'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Product>>(
      key: ValueKey(_refreshKey),
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? Colors.grey[900] : Colors.blueGrey[50],
              child: Row(
                children: [
                  const Text('Gestion de Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualiser',
                    onPressed: _loadProducts,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Table Header - Hide on Mobile
            if (!Responsive.isMobile(context))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? Colors.grey[850] : Colors.grey[200],
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('Catégorie', style: _headerStyle())),
                    Expanded(flex: 2, child: Text('Marque', style: _headerStyle())),
                    Expanded(flex: 3, child: Text('Modèle', style: _headerStyle())),
                    Expanded(flex: 1, child: Text('Variantes', textAlign: TextAlign.center, style: _headerStyle())),
                    Expanded(flex: 2, child: Text('Stock total', textAlign: TextAlign.center, style: _headerStyle())),
                    Expanded(flex: 2, child: Text('Prix d\'achat', textAlign: TextAlign.right, style: _headerStyle())),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: Text('Prix vente', textAlign: TextAlign.right, style: _headerStyle())),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: Text('Statut', textAlign: TextAlign.center, style: _headerStyle())),
                    Expanded(flex: 2, child: Text('Publication', textAlign: TextAlign.center, style: _headerStyle())),
                    const SizedBox(width: 24), // For expand icon space
                  ],
                ),
              ),
            if (!Responsive.isMobile(context))
              const Divider(height: 1),

            // Table Body
            Expanded(
              child: Builder(
                builder: (context) {
                  final sortedProducts = List<Product>.from(products);
                  sortedProducts.sort((a, b) {
                    int catCmp = (a.categorie?.nom ?? '').compareTo(b.categorie?.nom ?? '');
                    if (catCmp != 0) return catCmp;
                    int brandCmp = a.marque.compareTo(b.marque);
                    if (brandCmp != 0) return brandCmp;
                    return a.modele.compareTo(b.modele);
                  });

                  return ListView.builder(
                    itemCount: sortedProducts.length,
                    itemBuilder: (context, index) {
                      final p = sortedProducts[index];
                      bool showCategory = true;
                      bool showBrand = true;

                      if (index > 0) {
                        final prev = sortedProducts[index - 1];
                        if ((p.categorie?.nom ?? '') == (prev.categorie?.nom ?? '')) {
                          showCategory = false;
                          if (p.marque == prev.marque) {
                            showBrand = false;
                          }
                        }
                      }

                      return _ProductExpandableRow(
                        product: p,
                        isDark: isDark,
                        showCategory: showCategory,
                        showBrand: showBrand,
                        onAdjustStock: (varianteId, nom, stock) => _showAdjustStockDialog(varianteId, nom, stock),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  TextStyle _headerStyle() => const TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
}

class _ProductExpandableRow extends StatefulWidget {
  final Product product;
  final bool isDark;
  final bool showCategory;
  final bool showBrand;
  final Function(int, String, int) onAdjustStock;

  const _ProductExpandableRow({
    required this.product,
    required this.isDark,
    this.showCategory = true,
    this.showBrand = true,
    required this.onAdjustStock,
  });

  @override
  State<_ProductExpandableRow> createState() => _ProductExpandableRowState();
}

class _ProductExpandableRowState extends State<_ProductExpandableRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    
    // Calculate stock total
    int stockTotal = 0;
    for (var v in p.variantes) {
      stockTotal += v.stock;
    }

    final formatter = NumberFormat.currency(locale: 'fr', symbol: 'F', decimalDigits: 0);

    String getPriceText(Iterable<String?> prices) {
      double minP = double.infinity;
      double maxP = 0;
      bool hasPrice = false;
      for (var pStr in prices) {
        if (pStr == null || pStr.isEmpty || pStr == 'null') continue;
        final cleanStr = pStr.replaceAll(RegExp(r'[^0-9.]'), '');
        final pVal = double.tryParse(cleanStr) ?? 0;
        if (pVal > 0) {
          hasPrice = true;
          if (pVal < minP) minP = pVal;
          if (pVal > maxP) maxP = pVal;
        }
      }
      if (!hasPrice) return '-';
      if (minP == maxP) return formatter.format(minP);
      return '${formatter.format(minP)} - ${formatter.format(maxP)}';
    }
    
    String formatSinglePrice(String? pStr) {
      if (pStr == null || pStr.isEmpty || pStr == 'null') return '-';
      final cleanStr = pStr.replaceAll(RegExp(r'[^0-9.]'), '');
      final pVal = double.tryParse(cleanStr);
      if (pVal == null || pVal == 0) return '-';
      return formatter.format(pVal);
    }

    String prixAchatText = getPriceText(p.variantes.map((v) => v.prixAchat));
    String prixVenteText = getPriceText(p.variantes.map((v) => v.prix));

    Widget desktopRow = Row(
      children: [
        Expanded(flex: 2, child: Text(widget.showCategory ? (p.categorie?.nom ?? '-') : '', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: widget.showCategory ? FontWeight.bold : FontWeight.normal))),
        Expanded(flex: 2, child: Text(widget.showBrand ? (p.marque.isNotEmpty ? p.marque : '-') : '', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: widget.showBrand ? FontWeight.bold : FontWeight.normal))),
        Expanded(flex: 3, child: Text(p.modele.isNotEmpty ? p.modele : p.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text('${p.variantes.length}', textAlign: TextAlign.center)),
        Expanded(
          flex: 2, 
          child: Text(
            '$stockTotal', 
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: stockTotal <= 5 ? Colors.red : (widget.isDark ? Colors.white : Colors.black)),
          )
        ),
        Expanded(flex: 2, child: Text(prixAchatText, textAlign: TextAlign.right)),
        const SizedBox(width: 24),
        Expanded(flex: 3, child: Text(prixVenteText, textAlign: TextAlign.right)),
        const SizedBox(width: 24),
        Expanded(
          flex: 2, 
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stockTotal > 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stockTotal > 0 ? 'Disponible' : 'Rupture',
                style: TextStyle(color: stockTotal > 0 ? Colors.green : Colors.red, fontSize: 12),
              ),
            ),
          )
        ),
        Expanded(
          flex: 2,
          child: Text(
            p.statutPublication,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.statutPublication.toLowerCase() == 'publié' ? Colors.green : Colors.grey),
          ),
        ),
        Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
      ],
    );

    Widget mobileCard = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: widget.isDark ? Colors.grey[800]! : Colors.grey[300]!)),
      color: _isExpanded ? (widget.isDark ? Colors.grey[800] : Colors.blue[50]) : (widget.isDark ? Colors.grey[900] : Colors.white),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.modele.isNotEmpty ? p.modele : p.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('${p.categorie?.nom ?? "-"} | ${p.marque.isNotEmpty ? p.marque : "-"}', style: TextStyle(color: widget.isDark ? Colors.grey[400] : Colors.grey[700])),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stock: $stockTotal', style: TextStyle(fontWeight: FontWeight.bold, color: stockTotal <= 5 ? Colors.red : (widget.isDark ? Colors.white : Colors.black))),
                      const SizedBox(height: 4),
                      Text('Prix: $prixVenteText', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stockTotal > 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stockTotal > 0 ? 'Disponible' : 'Rupture',
                      style: TextStyle(color: stockTotal > 0 ? Colors.green : Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: [
        if (Responsive.isMobile(context)) mobileCard else InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isExpanded 
                  ? (widget.isDark ? Colors.grey[800] : Colors.blue[50])
                  : Colors.transparent,
            ),
            child: desktopRow,
          ),
        ),
        
        // Variants Sub-table
        if (_isExpanded && Responsive.isMobile(context))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: p.variantes.map((v) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: widget.isDark ? Colors.grey[850] : Colors.grey[100],
                  elevation: 0,
                  child: ListTile(
                    title: Text(v.desc.isNotEmpty ? v.desc : 'Standard', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stock: ${v.stock} | Prix: ${formatSinglePrice(v.prix)}'),
                        if (v.ram != null || v.stockage != null)
                          Text('${v.ram ?? "-"} RAM | ${v.stockage ?? "-"}'),
                      ],
                    ),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_square, size: 16),
                      label: const Text('Ajuster'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: () {
                        widget.onAdjustStock(v.id, v.desc.isNotEmpty ? v.desc : 'Standard', v.stock);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else if (_isExpanded)
          Container(
            color: widget.isDark ? Colors.black26 : Colors.grey[50],
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: widget.isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(widget.isDark ? Colors.grey[850] : Colors.grey[200]),
                  columns: const [
                    DataColumn(label: Text('Variante')),
                    DataColumn(label: Text('RAM')),
                    DataColumn(label: Text('Stockage')),
                    DataColumn(label: Text('Couleur')),
                    DataColumn(label: Text('Prix Achat')),
                    DataColumn(label: Text('Prix Vente')),
                    DataColumn(label: Text('Quantité', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: p.variantes.map((v) {
                    return DataRow(
                      cells: [
                        DataCell(Text(v.desc.isNotEmpty ? v.desc : 'Standard')),
                        DataCell(Text(v.ram ?? '-')),
                        DataCell(Text(v.stockage ?? '-')),
                        DataCell(
                          Row(
                            children: [
                              if (v.couleurHex != null)
                                Container(
                                  width: 16, height: 16,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(v.couleurHex!.replaceFirst('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                ),
                              Text(v.couleurNom ?? '-'),
                            ],
                          )
                        ),
                        DataCell(Text(formatSinglePrice(v.prixAchat))),
                        DataCell(Text(formatSinglePrice(v.prix))),
                        DataCell(
                          Text(
                            '${v.stock}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: v.stock <= 5 ? Colors.red : (widget.isDark ? Colors.white : Colors.black87),
                            )
                          )
                        ),
                        DataCell(
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit_square, size: 16),
                            label: const Text('Ajuster Stock'),
                            onPressed: () {
                              widget.onAdjustStock(v.id, v.desc.isNotEmpty ? v.desc : 'Standard', v.stock);
                            },
                          )
                        ),
                      ]
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        if (!Responsive.isMobile(context))
          const Divider(height: 1),
      ],
    );
  }
}
