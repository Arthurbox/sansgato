// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_element
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLivraison = true; // true = Livraison, false = Expédition
  String _selectedPayment = 'wave'; // 'orange', 'moov', 'wave'
  bool _isLoading = false;

  static const String kGoogleApiKey = 'AIzaSyApG8kZQwUunR2tFCX1o019tfJoS8li2m4';

  Future<List<Map<String, String>>> _getPlaces(String input) async {
    if (input.isEmpty) return [];
    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$kGoogleApiKey&components=country:bf';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List).map<Map<String, String>>((p) => {
            'description': p['description'] as String,
            'place_id': p['place_id'] as String,
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching places: $e');
    }
    return [];
  }

  Future<void> _getPlaceDetails(String placeId, String description) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          setState(() {
            _selectedQuartier = description;
            _latitude = location['lat'];
            _longitude = location['lng'];
          });
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_latitude!, _longitude!), 16));
        }
      }
    } catch (e) {
      debugPrint('Error fetching place details: $e');
    }
  }

  // Controllers Livraison
  String? _selectedQuartier;
  final List<String> _quartiers = [
    'Ouaga 2000', 'Karpala', 'Pissy', 'Cissin', 'Patte d\'Oie', 'Dassasgho', 
    'Gounghin', 'Koulouba', 'Kamsonghin', 'Samandin', 'Dapoya', 'Larlé', 
    'Baskuy', 'Hamdallaye', 'Tanghin', 'Tampouy', 'Kilwin', 'Rimkièta', 
    'Somgandé', 'Kossodo', 'Wayalghin', 'Bendogo', 'Balkuy', 'Nagrin', 
    'Zongo', 'Ouidi', 'Paspanga', 'Kologh-Naba', 'Toécin', 'Noncin', 
    'Rayongo', 'Bonheur-Ville', 'Belle-Ville', 'Bissighin', 'Bassinko', 
    'Silmissin', 'Kossyam', 'Zagtouli', 'Yagma', 'Kamboincé'
  ];
  double? _latitude;
  double? _longitude;
  GoogleMapController? _mapController;

  // Controllers Expédition
  final _nomCompletController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _villeController = TextEditingController();
  String? _selectedCompagnie;
  final _commentaireController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nomCompletController.dispose();
    _telephoneController.dispose();
    _villeController.dispose();
    _villeController.dispose();
    _commentaireController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Vérification position si livraison
    if (_isLivraison && (_latitude == null || _longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter votre position.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> payload = {
      "mode_reception": _isLivraison ? "livraison" : "expedition",
      "payment_method": "mobile_money", // Backend fallback pour l'instant
    };

    if (_isLivraison) {
      payload["adresse_livraison"] = {
        "latitude": _latitude,
        "longitude": _longitude,
        "adresse_complete": _selectedQuartier ?? "",
        "commentaire": "",
      };
    } else {
      final parts = _nomCompletController.text.trim().split(' ');
      final nom = parts.isNotEmpty ? parts[0] : '';
      final prenom = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      
      payload["adresse_expedition"] = {
        "nom": nom,
        "prenom": prenom,
        "telephone": _telephoneController.text.trim(),
        "ville": _villeController.text.trim(),
        "adresse": _selectedCompagnie ?? "",
        "commentaire": _commentaireController.text.trim(),
      };
    }

    final error = await ref.read(cartProvider.notifier).checkout(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        // Rediriger vers l'accueil
        ref.read(selectedTabProvider.notifier).setTab(0);
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande validée avec succès !'),
            backgroundColor: Color(0xFF00A9C1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez activer le GPS.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions refusées.')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions refusées définitivement.')));
      return;
    } 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recherche de votre position...')));
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    
    if (mounted) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 16));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFF00A9C1);
    final Color bg = isDark ? const Color(0xFF111318) : const Color(0xFFF5F5F5);
    final Color cardBg = isDark ? const Color(0xFF1C1F2A) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final cartState = ref.watch(cartProvider);
    final total = cartState.value?.totalPrice ?? 0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Validation de commande', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Mode de réception ───
              Text('Mode de réception', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLivraison = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLivraison ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Livraison',
                            style: TextStyle(
                              color: _isLivraison ? Colors.white : Colors.grey, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLivraison = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLivraison ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Expédition',
                            style: TextStyle(
                              color: !_isLivraison ? Colors.white : Colors.grey, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Formulaire ───
              if (_isLivraison) ...[
                const Text('Adresse de livraison', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            height: 110,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(_latitude ?? 12.3681, _longitude ?? -1.5271),
                                  zoom: _latitude == null ? 11 : 16,
                                ),
                                onMapCreated: (controller) => _mapController = controller,
                                markers: _latitude == null ? {} : {
                                  Marker(
                                    markerId: const MarkerId('livraison'),
                                    position: LatLng(_latitude!, _longitude!),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                  )
                                },
                                onTap: (latLng) {
                                  setState(() {
                                    _latitude = latLng.latitude;
                                    _longitude = latLng.longitude;
                                  });
                                },
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            child: GestureDetector(
                              onTap: _getLocation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C303A).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Ajouter votre position',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedQuartier,
                        decoration: InputDecoration(
                          labelText: 'Quartier',
                          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 16),
                          filled: true,
                          fillColor: cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF00A9C1), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500),
                        items: _quartiers.map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 18)))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedQuartier = val;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez sélectionner un quartier';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('Informations d\'expédition', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField(context, _nomCompletController, 'Nom complet', validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ce champ est requis';
                  if (!RegExp(r'^[a-zA-ZÀ-ÿ\s-]{3,}$').hasMatch(value)) {
                    return 'Veuillez entrer un nom valide';
                  }
                  if (!value.trim().contains(' ')) return 'Veuillez entrer votre nom et prénom';
                  return null;
                }),
                const SizedBox(height: 12),
                _buildTextField(context, _telephoneController, 'Numéro de téléphone', keyboardType: TextInputType.phone, validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ce champ est requis';
                  // Validation pour numéro du Burkina (8 chiffres, ou préfixé)
                  if (!RegExp(r'^(\+226|00226)?([0-9]{8})$').hasMatch(value.replaceAll(' ', ''))) {
                    return 'Numéro invalide (ex: 70 12 34 56)';
                  }
                  return null;
                }),
                const SizedBox(height: 12),
                _buildTextField(context, _villeController, 'Ville de destination'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCompagnie,
                  hint: const Text('Compagnie de transport', style: TextStyle(color: Colors.grey)),
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor),
                  items: ['STAF', 'TSR', 'RAHIMO', 'ELITIS', 'RAKIETA', 'SARAMAYA']
                      .map((compagnie) => DropdownMenuItem(
                            value: compagnie,
                            child: Text(compagnie),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCompagnie = value),
                  validator: (value) => value == null ? 'Veuillez choisir une compagnie' : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(context, _commentaireController, 'Commentaire / Indications (Optionnel)', required: false),
              ],
              const SizedBox(height: 20),

              // ─── Paiement ───
              Text('Paiement', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOrangeLogo(),
                  _buildMoovLogo(),
                  _buildWaveLogo(),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
        ),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: primary,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Confirmer - ${(total + (_isLivraison ? 1000 : 2000)).toInt()} F',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String hint, {bool required = true, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fieldBg = isDark ? const Color(0xFF1C1F2A) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      validator: validator ?? (required ? (value) => value == null || value.isEmpty ? 'Champ requis' : null : null),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildOrangeLogo() {
    final isSelected = _selectedPayment == 'orange';
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = 'orange'),
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00A9C1).withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? const Color(0xFF00A9C1) : Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00A9C1).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Image.asset(
            'assets/icons/orange.png',
            width: 80,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildMoovLogo() {
    final isSelected = _selectedPayment == 'moov';
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = 'moov'),
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00A9C1).withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? const Color(0xFF00A9C1) : Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00A9C1).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Image.asset(
            'assets/icons/image.png',
            width: 80,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildWaveLogo() {
    final isSelected = _selectedPayment == 'wave';
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = 'wave'),
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00A9C1).withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? const Color(0xFF00A9C1) : Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00A9C1).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Image.asset(
            'assets/icons/wave.png',
            width: 80,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
