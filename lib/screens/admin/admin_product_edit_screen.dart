import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/admin_api_service.dart';

class AdminProductEditScreen extends StatefulWidget {
  final Product product;
  const AdminProductEditScreen({super.key, required this.product});

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _modeleController;
  late TextEditingController _descController;
  String _etat = 'neuf';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.product.nomComplet);
    _modeleController = TextEditingController(text: widget.product.modele);
    _descController = TextEditingController(text: widget.product.description ?? '');
    _etat = widget.product.etat;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _modeleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final data = {
        'nom_complet': _nomController.text,
        'modele': _modeleController.text,
        'description': _descController.text,
        'etat': _etat,
        'categorie': widget.product.categorie?.id,
        'marque': widget.product.marqueId,
      };

      await AdminApiService.updateProduct(widget.product.id, data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produit modifié avec succès'), backgroundColor: Colors.green));
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
        title: const Text('Modifier Produit'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modeleController,
                decoration: const InputDecoration(labelText: 'Modèle', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _etat,
                decoration: const InputDecoration(labelText: 'État', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'neuf', child: Text('Neuf')),
                  DropdownMenuItem(value: 'occasion', child: Text('Occasion')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _etat = val);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isDark ? primaryColor : Colors.deepPurple, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
