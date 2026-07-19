import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'main_scaffold.dart';
import 'login_screen.dart';
import 'admin_main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String purpose; // 'register' ou 'login'

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.purpose,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _otpError;

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _verify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _otpError = 'Veuillez saisir les 6 chiffres');
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    final result = await _authService.verifyOtp(
      phoneNumber: widget.phoneNumber,
      code: code,
      purpose: widget.purpose,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vérification réussie !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Aller sur l'accueil ou l'admin selon le rôle et effacer toute la pile de navigation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScaffold()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        String errorMessage = 'Code de vérification invalide ou expiré';
        final errors = result['errors'];
        if (errors is Map) {
          setState(() {
            if (errors.containsKey('code')) {
              _otpError = (errors['code'] is List)
                  ? (errors['code'] as List).join('\n')
                  : errors['code'].toString();
            }
          });

          if (errors.containsKey('non_field_errors')) {
            errorMessage = (errors['non_field_errors'] as List).join('\n');
          } else if (errors.containsKey('detail')) {
            errorMessage = errors['detail'].toString();
          } else if (errors.containsKey('code')) {
            errorMessage = (errors['code'] is List)
                ? (errors['code'] as List).join('\n')
                : errors['code'].toString();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A9C1);
    final textColor = isDark ? Colors.white : primaryColor;
    final inputFillColor = isDark ? Colors.grey[850] : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Validation OTP'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
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
                  Icons.sms_outlined,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Code de vérification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez le code OTP à 6 chiffres envoyé au numéro :\n${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 32),
                // OTP Input (6 carrés)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          height: 55,
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: EdgeInsets.zero,
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _otpError != null ? Colors.red : primaryColor.withOpacity(0.5))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              }
                              if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                              // Validation automatique si tous les champs sont remplis
                              if (_controllers.every((c) => c.text.isNotEmpty)) {
                                FocusScope.of(context).unfocus();
                                _verify();
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (_otpError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _otpError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 4),
                // Bouton Coller
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null && data.text != null) {
                        final text = data.text!.trim().replaceAll(RegExp(r'[^0-9]'), '');
                        if (text.length >= 6) {
                          for (int i = 0; i < 6; i++) {
                            _controllers[i].text = text[i];
                          }
                          FocusScope.of(context).unfocus();
                          _verify();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Le texte copié ne contient pas de code valide à 6 chiffres.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.paste, size: 18),
                    label: const Text('Coller'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
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
                          'Vérifier le code',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),
                // Helper message in development
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.amber.shade900.withOpacity(0.2) : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.amber.shade700 : Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "En développement, le code de validation est affiché dans la console du backend Django.",
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.black87),
                        ),
                      ),
                    ],
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
