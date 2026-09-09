// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/auth_service.dart';
import '../config/router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isPhoneRegistration = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _usernameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _usernameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
    });

    final result = await _authService.register(
      fullName: _usernameController.text.trim(),
      phoneNumber: _isPhoneRegistration ? '+226${_phoneController.text.trim()}' : null,
      email: !_isPhoneRegistration ? _emailController.text.trim() : null,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      if (mounted) {
        if (result['requires_otp'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Inscription réussie, code OTP envoyé !'),
              backgroundColor: Colors.green,
            ),
          );
          context.push(AppRoutes.otp, extra: {
            'phoneNumber': result['phone_number'] ?? '+226${_phoneController.text.trim()}',
            'purpose': 'register',
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Inscription réussie !'),
              backgroundColor: Colors.green,
            ),
          );
          context.go(AppRoutes.home);
        }
      }
    } else {
      if (mounted) {
        String errorMessage = 'Veuillez corriger les erreurs ci-dessous';
        final errors = result['errors'];
        if (errors is Map) {
          setState(() {
            if (errors.containsKey('username')) {
              _usernameError = (errors['username'] is List)
                  ? (errors['username'] as List).join('\n')
                  : errors['username'].toString();
            }
            if (errors.containsKey('phone_number')) {
              _phoneError = (errors['phone_number'] is List)
                  ? (errors['phone_number'] as List).join('\n')
                  : errors['phone_number'].toString();
            }
            if (errors.containsKey('password')) {
              _passwordError = (errors['password'] is List)
                  ? (errors['password'] as List).join('\n')
                  : errors['password'].toString();
            }
          });

          if (errors.containsKey('non_field_errors')) {
            errorMessage = (errors['non_field_errors'] as List).join('\n');
          } else if (errors.containsKey('detail')) {
            errorMessage = errors['detail'].toString();
          } else if (errors.containsKey('password')) {
            errorMessage = (errors['password'] is List)
                ? (errors['password'] as List).join('\n')
                : errors['password'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isGoogleInitialized = false;

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
    });

    String? token;
    
    try {
      if (provider == 'google') {
        debugPrint('[DEBUG] Démarrage Google Sign-In...');
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;
        if (!_isGoogleInitialized) {
          debugPrint('[DEBUG] Initialisation Google Sign-In avec serverClientId...');
          await googleSignIn.initialize(
            serverClientId: '604730974010-gqdtusugoh48h7f16obiqghrec8nd4q7.apps.googleusercontent.com',
          );
          _isGoogleInitialized = true;
          debugPrint('[DEBUG] Initialisation OK');
        }
        
        debugPrint('[DEBUG] Appel authenticate()...');
        final account = await googleSignIn.authenticate();
        debugPrint('[DEBUG] account = $account');
        debugPrint('[DEBUG] Email: ${account.email}');
        final GoogleSignInAuthentication auth = account.authentication;
        token = auth.idToken;
        debugPrint('[DEBUG] idToken = ${token == null ? "NULL !" : "${token.substring(0, 50)}..."}');
      } else if (provider == 'facebook') {
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['public_profile', 'email'],
        );
        if (result.status == LoginStatus.success) {
          token = result.accessToken?.tokenString;
        } else {
          setState(() => _isLoading = false);
          return; // User canceled or error
        }
      }

      if (token == null) throw Exception('Token non reçu (idToken est null)');

      debugPrint('[DEBUG] Envoi du token au backend Django...');
      final result = await _authService.socialLogin(
        provider: provider,
        token: token,
      );
      debugPrint('[DEBUG] Réponse backend: $result');

      setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
          if (result['requires_phone'] == true) {
            context.push(AppRoutes.socialPhone, extra: {
              'email': result['email'] ?? '',
              'name': result['name'] ?? '',
              'provider': result['provider'] ?? provider,
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connexion sociale réussie !'),
                backgroundColor: Colors.green,
              ),
            );
            context.go(AppRoutes.home);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['errors']?['detail'] ?? 'Erreur de connexion sociale'), 
              backgroundColor: Colors.red
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[DEBUG] EXCEPTION: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00A9C1); // Cyan
    const Color darkColor = Color(0xFF002244); // Dark Blue
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : darkColor;
    final inputFillColor = isDark ? Colors.grey[850] : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Inscription',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Toggle Button (Visual only for now to match mockup)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isPhoneRegistration = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isPhoneRegistration ? (isDark ? Colors.grey[700] : Colors.white) : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: _isPhoneRegistration
                                    ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Text('Téléphone', style: TextStyle(color: _isPhoneRegistration ? textColor : Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isPhoneRegistration = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isPhoneRegistration ? primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: !_isPhoneRegistration
                                    ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Text('Email', style: TextStyle(color: !_isPhoneRegistration ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username -> Nom complet
                  const Text("Nom complet", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'ex: Awa Sawadogo',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: inputFillColor,
                      errorText: _usernameError,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor, width: 2)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Ce champ est requis';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_isPhoneRegistration) ...[
                    // Phone Number
                    const Text('Numéro de téléphone', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: '12345678',
                        prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                        prefixText: '+226 ',
                        prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                        hintStyle: const TextStyle(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: inputFillColor,
                        errorText: _phoneError,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Ce champ est requis';
                        return null;
                      },
                    ),
                  ] else ...[
                    // Email
                    const Text('Adresse E-mail', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'ex: awa@example.com',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: inputFillColor,
                        errorText: _emailError,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Ce champ est requis';
                        if (!value.contains('@')) return 'E-mail invalide';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Password
                  const Text('Mot de passe', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: inputFillColor,
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor, width: 2)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ce champ est requis';
                      return null;
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text('min. 8 caractères • 1 majuscule • 1 chiffre', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  const Text('Confirmer le mot de passe', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: inputFillColor,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor, width: 2)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 2)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ce champ est requis';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Suivant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),

                  // Link to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Vous avez déjà un compte ? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          context.go(AppRoutes.login);
                        },
                        child: Text(
                          "Se connecter",
                          style: TextStyle(color: isDark ? primaryColor : darkColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationColor: isDark ? primaryColor : darkColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Social Login
                  const Text("Se connecter avec", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google
                      InkWell(
                        onTap: _isLoading ? null : () => _handleSocialLogin('google'),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300), color: inputFillColor),
                          child: Center(child: Text('G', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Facebook
                      InkWell(
                        onTap: _isLoading ? null : () => _handleSocialLogin('facebook'),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300), color: inputFillColor),
                          child: const Center(child: Icon(Icons.facebook, color: Color(0xFF1877F2), size: 30)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Apple
                      InkWell(
                        onTap: () {}, // To be implemented or removed
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300), color: inputFillColor),
                          child: Center(child: Icon(Icons.apple, color: isDark ? Colors.white : Colors.black, size: 30)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
