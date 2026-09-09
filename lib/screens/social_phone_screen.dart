import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../config/router.dart';

class SocialPhoneScreen extends StatefulWidget {
  final String email;
  final String name;
  final String provider;

  const SocialPhoneScreen({
    super.key,
    required this.email,
    required this.name,
    required this.provider,
  });

  @override
  State<SocialPhoneScreen> createState() => _SocialPhoneScreenState();
}

class _SocialPhoneScreenState extends State<SocialPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _phoneError = null;
    });

    final result = await _authService.socialRegister(
      email: widget.email,
      name: widget.name,
      phoneNumber: '+226${_phoneController.text.trim()}',
      provider: widget.provider,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Code OTP envoyé !'),
            backgroundColor: Colors.green,
          ),
        );
        context.push(AppRoutes.otp, extra: {
          'phoneNumber': result['phone_number'] ?? '+226${_phoneController.text.trim()}',
          'purpose': 'register',
        });
      }
    } else {
      if (mounted) {
        String errorMessage = 'Une erreur est survenue';
        final errors = result['errors'];
        if (errors is Map) {
          setState(() {
            if (errors.containsKey('phone_number')) {
              _phoneError = (errors['phone_number'] is List)
                  ? (errors['phone_number'] as List).join('\n')
                  : errors['phone_number'].toString();
            }
          });
          if (errors.containsKey('detail')) {
            errorMessage = errors['detail'].toString();
          } else if (errors.containsKey('non_field_errors')) {
            errorMessage = (errors['non_field_errors'] as List).join('\n');
          }
        }
        if (_phoneError == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);
    final textColor = isDark ? Colors.white : primaryColor;
    final inputFillColor = isDark ? Colors.grey[850] : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Complétez votre profil'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.phone_android,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Bienvenue, ${widget.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pour sécuriser votre compte, veuillez lier un numéro de téléphone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixText: '+226 ',
                    prefixStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    hintText: '12345678',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.phone),
                    errorText: _phoneError,
                    filled: true,
                    fillColor: inputFillColor,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le numéro de téléphone est requis';
                    }
                    if (value.trim().length != 8) {
                      return 'Le numéro doit comporter exactement 8 chiffres';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Envoyer le code OTP',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
