import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';
import 'main_scaffold.dart';
import 'admin_main_screen.dart';
import 'register_screen.dart';
import 'social_phone_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  final bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String identifier = _phoneController.text.trim();
    if (RegExp(r'^\d{8}$').hasMatch(identifier)) {
      identifier = '+226$identifier';
    }

    final result = await _authService.login(
      identifier: identifier,
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      if (mounted) {
        if (result['requires_otp'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Code OTP envoyé !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                phoneNumber: result['phone_number'] ?? _phoneController.text.trim(),
                purpose: 'login',
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScaffold()),
          );
        }
      }
    } else {
      if (mounted) {
        String errorMessage = 'Une erreur est survenue';
        final errors = result['errors'];
        if (errors is Map) {
          if (errors.containsKey('non_field_errors')) {
            errorMessage = (errors['non_field_errors'] as List).join('\n');
          } else if (errors.containsKey('detail')) {
            errorMessage = errors['detail'].toString();
          } else {
            errorMessage = errors.values.map((v) {
              if (v is List) return v.join('\n');
              return v.toString();
            }).join('\n');
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
             Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SocialPhoneScreen(
                  email: result['email'] ?? '',
                  name: result['name'] ?? '',
                  provider: result['provider'] ?? provider,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connexion sociale réussie !'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScaffold()),
              (route) => false,
            );
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
                    'Connexion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Email / Phone Label
                  const Text(
                    'Email / Téléphone',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'vous@exemple.com',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: inputFillColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ce champ est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Password Label
                  const Text(
                    'Mot de passe',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le mot de passe est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Remember me & Forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                              activeColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Se souvenir de moi', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(color: isDark ? primaryColor : darkColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
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
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 32),

                  // Link to Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Nouveau ici ? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Créer un compte",
                          style: TextStyle(
                            color: isDark ? primaryColor : darkColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: isDark ? primaryColor : darkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Social Login
                  const Text(
                    "Se connecter avec",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google
                      InkWell(
                        onTap: _isLoading ? null : () => _handleSocialLogin('google'),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                            color: inputFillColor,
                          ),
                          child: Center(
                            child: Text('G', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Facebook
                      InkWell(
                        onTap: _isLoading ? null : () => _handleSocialLogin('facebook'),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                            color: inputFillColor,
                          ),
                          child: const Center(
                            child: Icon(Icons.facebook, color: Color(0xFF1877F2), size: 30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Apple
                      InkWell(
                        onTap: () {}, // Not implemented yet
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                            color: inputFillColor,
                          ),
                          child: Center(
                            child: Icon(Icons.apple, color: isDark ? Colors.white : Colors.black, size: 30),
                          ),
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

