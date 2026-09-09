import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _overviewData = {};



  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getDashboardOverview();
      setState(() {
        _overviewData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() => _isLoading = false);
      }
    }
  }


  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 F';
    return NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vue Globale', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Ligne 1 : Ventes
            Row(
              children: [
                Expanded(child: _buildStatCard('Ventes (Aujourd\'hui)', _formatCurrency(_overviewData['ventes_jour']), Icons.today, Colors.blue, isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Ventes (Ce mois)', _formatCurrency(_overviewData['ventes_mois']), Icons.calendar_month, Colors.green, isDark)),
              ],
            ),
            const SizedBox(height: 12),

            // Record du mois
            if (_overviewData['top_mois'] != null && _overviewData['top_mois'].toString().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Mois Historique 🏆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${_overviewData['top_mois']} : ${_formatCurrency(_overviewData['top_mois_montant'])}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            // Ligne 2 : Commandes & Alertes
            Row(
              children: [
                Expanded(child: _buildStatCard('Cmd. en attente', '${_overviewData['commandes_attente']}', Icons.pending_actions, Colors.orange, isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Ruptures stock', '${_overviewData['rupture_stock']}', Icons.warning_amber, Colors.red, isDark)),
              ],
            ),
            const SizedBox(height: 12),

            // Ligne 3 : Communauté & Commandes du jour
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Clients', '${_overviewData['total_clients']}', Icons.people, Colors.teal, isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Nouv. Cmd. (Jour)', '${_overviewData['commandes_jour']}', Icons.shopping_bag, Colors.indigo, isDark)),
              ],
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
