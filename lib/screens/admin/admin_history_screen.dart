import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import 'package:intl/intl.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  bool _isFiltering = false;
  Map<String, dynamic>? _filteredData;
  DateTime? _selectedDate;
  String _filterMode = 'Mois'; // 'Mois' ou 'Jour'

  Future<void> _loadFilteredData() async {
    if (_selectedDate == null) return;
    
    setState(() => _isFiltering = true);
    try {
      final data = await AdminApiService.getDashboardFiltered(
        year: _selectedDate!.year,
        month: _selectedDate!.month,
        day: _filterMode == 'Jour' ? _selectedDate!.day : null,
      );
      setState(() {
        _filteredData = data;
        _isFiltering = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() => _isFiltering = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Sélectionner une date pour le filtre',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadFilteredData();
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 F';
    return NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Ventes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtre Historique', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Filtrer par :'),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _filterMode,
                          items: <String>['Mois', 'Jour'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _filterMode = newValue!;
                              _selectedDate = null;
                              _filteredData = null;
                            });
                          },
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_selectedDate == null ? 'Choisir date' : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                        ),
                      ],
                    ),
                    
                    if (_isFiltering)
                      const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                    else if (_filteredData != null)
                      _buildFilteredResults(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredResults() {
    final totalVentes = _filteredData!['total_ventes'] ?? 0;
    final nbCommandes = _filteredData!['nombre_commandes'] ?? 0;
    final commandes = _filteredData!['commandes'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: Column(
            children: [
              Text('Résultat pour la période', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_formatCurrency(totalVentes), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[900])),
              Text('$nbCommandes commande(s) trouvée(s)', style: TextStyle(color: Colors.green[700])),
            ],
          ),
        ),
        if (commandes.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Liste des commandes (Aperçu) :', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: commandes.length,
            itemBuilder: (context, index) {
              final cmd = commandes[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long, color: Colors.grey),
                title: Text('Cmd #${cmd['id']} - ${cmd['user']}'),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(cmd['created_at']))),
                trailing: Text(_formatCurrency(cmd['total']), style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ]
      ],
    );
  }
}
