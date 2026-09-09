import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import 'package:intl/intl.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // --- Bilan ---
  bool _isLoadingReport = true;
  Map<String, dynamic> _reportData = {};
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth = DateTime.now().month;

  // --- Employés ---
  bool _isLoadingEmployees = true;
  List<dynamic> _employees = [];

  // --- Charges ---
  bool _isLoadingExpenses = true;
  List<dynamic> _expenses = [];
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadReport();
    _loadEmployees();
    _loadExpenses();
    _loadCategories();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoadingReport = true);
    try {
      final data = await AdminApiService.getFinanceReport(year: _selectedYear, month: _selectedMonth);
      setState(() { _reportData = data; _isLoadingReport = false; });
    } catch (e) {
      if (mounted) {
        _showError('Erreur Bilan: $e');
        setState(() => _isLoadingReport = false);
      }
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final data = await AdminApiService.getEmployees();
      setState(() { _employees = data; _isLoadingEmployees = false; });
    } catch (e) {
      if (mounted) {
        _showError('Erreur employés: $e');
        setState(() => _isLoadingEmployees = false);
      }
    }
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoadingExpenses = true);
    try {
      final data = await AdminApiService.getExpenses();
      setState(() { _expenses = data; _isLoadingExpenses = false; });
    } catch (e) {
      if (mounted) {
        _showError('Erreur charges: $e');
        setState(() => _isLoadingExpenses = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await AdminApiService.getExpenseCategories();
      setState(() => _categories = cats);
    } catch (e) {
      debugPrint('Erreur catégories: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  String _fmt(dynamic amount) {
    if (amount == null) return '0 F';
    return NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(amount);
  }

  // ──────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1117) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1D26) : Colors.white,
        elevation: 0,
        title: const Text('Finances & Comptabilité',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Bilan Financier', icon: Icon(Icons.account_balance_outlined, size: 20)),
            Tab(text: 'Dépenses', icon: Icon(Icons.receipt_long_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportTab(isDark),
          _buildExpensesTab(isDark),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // ONGLET 1 : BILAN
  // ──────────────────────────────────────────────────────────────

  Widget _buildReportTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodFilter(isDark),
          const SizedBox(height: 16),
          if (_isLoadingReport)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else ...[
            _buildReportCard('📈 Chiffre d\'Affaires', _reportData['chiffre_affaires'], Colors.blue, isDark),
            _buildReportCard('🛒 Coût des marchandises', _reportData['cout_marchandises'], Colors.orange, isDark),
            _buildReportCard('💰 Marge Brute', _reportData['marge_brute'], Colors.purple, isDark),
            const Divider(height: 32),
            _buildReportCard(
              '👥 Salaires (${_reportData['nb_employes'] ?? 0} employé(s))',
              _reportData['total_salaires'],
              Colors.teal,
              isDark,
            ),
            _buildReportCard('🏠 Charges fixes', _reportData['total_charges_fixes'], Colors.deepOrange, isDark),
            _buildReportCard('📋 Total charges', _reportData['total_charges'], Colors.red, isDark),
            const SizedBox(height: 20),
            _buildBeneficeCard(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodFilter(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          const Text('Période :'),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox(),
            items: List.generate(5, (i) => DateTime.now().year - i)
                .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                .toList(),
            onChanged: (val) {
              if (val != null) { setState(() => _selectedYear = val); _loadReport(); }
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<int?>(
              value: _selectedMonth,
              isExpanded: true,
              underline: const SizedBox(),
              hint: const Text('Année entière'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Année entière')),
                ...List.generate(12, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(DateFormat('MMMM', 'fr_FR').format(DateTime(2025, i + 1))),
                )),
              ],
              onChanged: (val) { setState(() => _selectedMonth = val); _loadReport(); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, dynamic amount, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700])),
        trailing: Text(_fmt(amount),
            style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBeneficeCard(bool isDark) {
    final benefice = (_reportData['benefice_net'] ?? 0);
    final isPositive = benefice >= 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF2ECC71), const Color(0xFF1ABC9C)]
              : [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.3),
            blurRadius: 16, offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            isPositive ? '✅  BÉNÉFICE NET' : '❌  DÉFICIT NET',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(_fmt(benefice),
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('CA − Marchandises − Salaires − Charges',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // ONGLET 2 : DÉPENSES
  // ──────────────────────────────────────────────────────────────

  Widget _buildExpensesTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── SECTION 1 : Employés & Salaires ───
          _buildSectionHeader(
            icon: Icons.people_alt_rounded,
            title: 'Salaires des Employés',
            color: Colors.teal,
            isDark: isDark,
            onAdd: _showAddEmployeeDialog,
          ),
          const SizedBox(height: 12),
          if (_isLoadingEmployees)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_employees.isEmpty)
            _buildEmptyState('Aucun employé enregistré', Icons.person_add_alt_1, isDark)
          else ...[
            _buildEmployeeTable(isDark),
            _buildTotalBadge(
              label: 'Total salaires / mois',
              amount: _employees.fold<double>(
                0.0,
                (sum, e) => sum + (double.tryParse(e['salaire_mensuel'].toString()) ?? 0.0),
              ),
              color: Colors.teal,
              isDark: isDark,
            ),
          ],

          const SizedBox(height: 28),

          // ─── SECTION 2 : Charges Fixes ───
          _buildSectionHeader(
            icon: Icons.home_work_rounded,
            title: 'Charges Fixes & Autres Dépenses',
            color: Colors.deepOrange,
            isDark: isDark,
            onAdd: _showAddExpenseDialog,
          ),
          const SizedBox(height: 12),
          if (_isLoadingExpenses)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_expenses.isEmpty)
            _buildEmptyState('Aucune charge enregistrée', Icons.add_card_rounded, isDark)
          else ...[
            ..._expenses.map((exp) => _buildExpenseCard(exp, isDark)),
            _buildTotalBadge(
              label: 'Total charges fixes',
              amount: _expenses.fold<double>(
                0.0,
                (sum, e) => sum + (double.tryParse(e['montant'].toString()) ?? 0.0),
              ),
              color: Colors.deepOrange,
              isDark: isDark,
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color))),
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add_circle_rounded, size: 18, color: color),
            label: Text('Ajouter', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          ),
        ],
      ),
    );
  }

  // ── Tableau des employés ──────────────────────────────────────────────────
  Widget _buildEmployeeTable(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;
    final headerBg = isDark ? const Color(0xFF0F1117) : const Color(0xFFF0FDFA);
    final headerText = Colors.teal;
    final bodyText = isDark ? Colors.grey[200]! : Colors.grey[800]!;
    final subText = Colors.grey[500]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── En-tête ──────────────────────────────────────────
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _colHeader('Nom complet', flex: 3, color: headerText),
                _colHeader('Poste / Fonction', flex: 3, color: headerText),
                _colHeader('Salaire / mois', flex: 2, color: headerText, align: TextAlign.right),
                _colHeader('Date embauche', flex: 2, color: headerText, align: TextAlign.center),
                const SizedBox(width: 80),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          // ── Lignes ───────────────────────────────────────────
          ...List.generate(_employees.length, (i) {
            final emp = _employees[i];
            final salaire = double.tryParse(emp['salaire_mensuel'].toString()) ?? 0.0;
            final isActif = emp['est_actif'] == true;
            final poste = (emp['poste'] as String?)?.isNotEmpty == true ? emp['poste'] as String : '—';
            final dateRaw = emp['date_embauche'] as String?;
            final dateStr = dateRaw != null
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dateRaw))
                : '—';
            final rowBg = i.isOdd
                ? (isDark ? const Color(0xFF141720) : const Color(0xFFF9FFFE))
                : bgColor;

            return Column(
              children: [
                Container(
                  color: rowBg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Nom
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: isActif
                                  ? Colors.teal.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),
                              child: Text(
                                (emp['nom'] as String).isNotEmpty
                                    ? (emp['nom'] as String)[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: isActif ? Colors.teal : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(emp['nom'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: bodyText),
                                      overflow: TextOverflow.ellipsis),
                                  if (!isActif)
                                    Text('Inactif',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[400])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Poste
                      Expanded(
                        flex: 3,
                        child: Text(poste,
                            style: TextStyle(fontSize: 13, color: subText),
                            overflow: TextOverflow.ellipsis),
                      ),
                      // Salaire
                      Expanded(
                        flex: 2,
                        child: Text(_fmt(salaire),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      // Date
                      Expanded(
                        flex: 2,
                        child: Text(dateStr,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: subText)),
                      ),
                      // Actions
                      SizedBox(
                        width: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 17),
                              color: Colors.blue,
                              onPressed: () => _showEditEmployeeDialog(emp),
                              tooltip: 'Modifier',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 17),
                              color: Colors.red,
                              onPressed: () => _confirmDeleteEmployee(emp),
                              tooltip: 'Supprimer',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _employees.length - 1)
                  Divider(height: 1, color: borderColor),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _colHeader(String label, {int flex = 1, Color? color, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.4,
          color: color ?? Colors.grey[600],
        ),
      ),
    );
  }


  Widget _buildExpenseCard(Map<String, dynamic> exp, bool isDark) {
    final montant = double.tryParse(exp['montant'].toString()) ?? 0.0;
    final desc = exp['description'] ?? '';
    final hasDesc = desc.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.deepOrange.withValues(alpha: 0.12),
          child: const Icon(Icons.receipt_long_rounded, color: Colors.deepOrange, size: 20),
        ),
        title: Text(exp['categorie_nom'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasDesc)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(desc, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(_fmt(montant),
                    style: const TextStyle(
                        color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text(exp['date'] ?? '',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ],
        ),
        isThreeLine: hasDesc,
        trailing: SizedBox(
          width: 88,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: Colors.blue,
                onPressed: () => _showEditExpenseDialog(exp),
                tooltip: 'Modifier',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                onPressed: () => _confirmDeleteExpense(exp),
                tooltip: 'Supprimer',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalBadge({
    required String label,
    required double amount,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          Text(_fmt(amount), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // DIALOGS : EMPLOYÉS
  // ──────────────────────────────────────────────────────────────

  void _showAddEmployeeDialog() => _showEmployeeDialog();

  void _showEditEmployeeDialog(Map<String, dynamic> emp) =>
      _showEmployeeDialog(existing: emp);

  void _showEmployeeDialog({Map<String, dynamic>? existing}) {
    final nomCtrl = TextEditingController(text: existing?['nom'] ?? '');
    final posteCtrl = TextEditingController(text: existing?['poste'] ?? '');
    final salaireCtrl = TextEditingController(
        text: existing?['salaire_mensuel']?.toString() ?? '');
    bool estActif = existing?['est_actif'] ?? true;
    DateTime? dateEmbauche = existing?['date_embauche'] != null
        ? DateTime.tryParse(existing!['date_embauche'])
        : null;
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit_outlined : Icons.person_add_alt_1, color: Colors.teal),
              const SizedBox(width: 8),
              Text(isEdit ? 'Modifier l\'employé' : 'Ajouter un employé'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nomCtrl, 'Nom complet *', Icons.person_outline),
                const SizedBox(height: 12),
                _dialogField(posteCtrl, 'Poste / Fonction (optionnel)', Icons.work_outline),
                const SizedBox(height: 12),
                _dialogField(salaireCtrl, 'Salaire mensuel (FCFA) *', Icons.attach_money, isNumber: true),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateEmbauche ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialog(() => dateEmbauche = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date d\'embauche (optionnel)',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      dateEmbauche != null
                          ? DateFormat('dd/MM/yyyy').format(dateEmbauche!)
                          : 'Sélectionner une date',
                      style: TextStyle(color: dateEmbauche != null ? null : Colors.grey),
                    ),
                  ),
                ),
                if (isEdit) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: estActif,
                    onChanged: (val) => setDialog(() => estActif = val),
                    title: Text(estActif ? 'Employé actif' : 'Employé inactif'),
                    activeThumbColor: Colors.teal,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () async {
                if (nomCtrl.text.trim().isEmpty ||
                    salaireCtrl.text.isEmpty) {
                  _showError('Veuillez remplir le nom et le salaire (*)');
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final data = {
                    'nom': nomCtrl.text.trim(),
                    'poste': posteCtrl.text.trim(),
                    'salaire_mensuel': double.parse(salaireCtrl.text),
                    'est_actif': estActif,
                    if (dateEmbauche != null)
                      'date_embauche': DateFormat('yyyy-MM-dd').format(dateEmbauche!),
                  };
                  if (isEdit) {
                    await AdminApiService.updateEmployee(existing['id'], data);
                    _showSuccess('Employé mis à jour');
                  } else {
                    await AdminApiService.createEmployee(data);
                    _showSuccess('Employé ajouté');
                  }
                  _loadEmployees();
                  _loadReport();
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
              child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEmployee(Map<String, dynamic> emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Supprimer cet employé ?'),
        content: Text('${emp['nom']} – ${emp['poste']}\nCette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AdminApiService.deleteEmployee(emp['id']);
                _showSuccess('Employé supprimé');
                _loadEmployees();
                _loadReport();
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // DIALOGS : CHARGES FIXES
  // ──────────────────────────────────────────────────────────────

  void _showAddExpenseDialog() {
    if (_categories.isEmpty) {
      _showError('Catégories non chargées, réessayez dans un instant.');
      _loadCategories();
      return;
    }

    int selectedCat = _categories.first['id'] as int;
    final montantCtrl = TextEditingController();
    final nomDepenseCtrl = TextEditingController(); // Nom pour "Autres"
    final descCtrl = TextEditingController();
    DateTime date = DateTime.now();

    // Vérifie si la catégorie sélectionnée est "Autres"
    bool isAutre(int catId) {
      final cat = _categories.firstWhere(
        (c) => c['id'] == catId,
        orElse: () => <String, dynamic>{},
      );
      final nom = (cat['nom'] as String? ?? '').toLowerCase();
      return nom.contains('autre');
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_card_rounded, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Nouvelle charge'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedCat,
                  decoration: InputDecoration(
                    labelText: 'Type de charge',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _categories.map<DropdownMenuItem<int>>((c) {
                    return DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(c['nom'] as String),
                    );
                  }).toList(),
                  onChanged: (val) => setDialog(() {
                    selectedCat = val!;
                    if (!isAutre(selectedCat)) nomDepenseCtrl.clear();
                  }),
                ),
                // ── Champ dynamique : Nom de la dépense (Autres) ──
                if (isAutre(selectedCat)) ...[
                  const SizedBox(height: 12),
                  _dialogField(nomDepenseCtrl, 'Nom de la dépense *', Icons.label_outline),
                ],
                const SizedBox(height: 12),
                _dialogField(montantCtrl, 'Montant (FCFA) *', Icons.attach_money, isNumber: true),
                const SizedBox(height: 12),
                _dialogField(descCtrl, 'Description (optionnel)', Icons.notes_outlined),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialog(() => date = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(date)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
              onPressed: () async {
                if (montantCtrl.text.isEmpty) {
                  _showError('Veuillez saisir un montant');
                  return;
                }
                if (isAutre(selectedCat) && nomDepenseCtrl.text.trim().isEmpty) {
                  _showError('Veuillez saisir le nom de la dépense');
                  return;
                }
                Navigator.pop(ctx);
                // Pour "Autres", le nom va dans la description si description vide
                final finalDesc = isAutre(selectedCat)
                    ? (descCtrl.text.trim().isEmpty
                        ? nomDepenseCtrl.text.trim()
                        : '${nomDepenseCtrl.text.trim()} – ${descCtrl.text.trim()}')
                    : descCtrl.text.trim();
                try {
                  await AdminApiService.addExpense(
                    selectedCat,
                    double.parse(montantCtrl.text),
                    DateFormat('yyyy-MM-dd').format(date),
                    finalDesc,
                  );
                  _showSuccess('Charge ajoutée');
                  _loadExpenses();
                  _loadReport();
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditExpenseDialog(Map<String, dynamic> exp) {
    final montantCtrl = TextEditingController(
        text: (double.tryParse(exp['montant'].toString()) ?? 0.0).toStringAsFixed(0));
    final descCtrl = TextEditingController(text: exp['description'] ?? '');
    DateTime date = DateTime.tryParse(exp['date'] ?? '') ?? DateTime.now();

    // Trouver la catégorie actuelle
    int selectedCat = exp['categorie'] is int
        ? exp['categorie'] as int
        : (_categories.isNotEmpty ? _categories.first['id'] as int : 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Modifier la charge'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Catégorie
                if (_categories.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: _categories.any((c) => c['id'] == selectedCat) ? selectedCat : _categories.first['id'] as int,
                    decoration: InputDecoration(
                      labelText: 'Type de charge',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _categories.map<DropdownMenuItem<int>>((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(c['nom'] as String),
                      );
                    }).toList(),
                    onChanged: (val) => setDialog(() => selectedCat = val!),
                  ),
                const SizedBox(height: 12),
                // Montant
                _dialogField(montantCtrl, 'Montant (FCFA) *', Icons.attach_money, isNumber: true),
                const SizedBox(height: 12),
                // Description
                _dialogField(descCtrl, 'Description (optionnel)', Icons.notes_outlined),
                const SizedBox(height: 12),
                // Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialog(() => date = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(date)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
              onPressed: () async {
                if (montantCtrl.text.isEmpty) {
                  _showError('Veuillez saisir un montant');
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await AdminApiService.updateExpense(exp['id'], {
                    'categorie': selectedCat,
                    'montant': double.parse(montantCtrl.text),
                    'date': DateFormat('yyyy-MM-dd').format(date),
                    'description': descCtrl.text,
                  });
                  _showSuccess('Charge mise à jour');
                  _loadExpenses();
                  _loadReport();
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExpense(Map<String, dynamic> exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Supprimer cette charge ?'),
        content: Text(
          '${exp['categorie_nom']} – ${_fmt(exp['montant'])}\nDate : ${exp['date']}\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AdminApiService.deleteExpense(exp['id']);
                _showSuccess('Charge supprimée');
                _loadExpenses();
                _loadReport();
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
