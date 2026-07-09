import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;

  const RegisterScreen({super.key, required this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.authService.register(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''),
                  style: DeckTheme.ibmPlexMono(
                      color: DeckColors.paper, fontSize: 10))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeckColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: DeckColors.paper,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  'FIRST NAME', '', _firstNameCtrl, null,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required!'
                                      : null),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                  'LAST NAME', '', _lastNameCtrl, null,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required!'
                                      : null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildTextField('EMAIL', 'you@example.com',
                            _emailCtrl, TextInputType.emailAddress,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Email required!'
                                : null),
                        const SizedBox(height: 14),
                        _buildTextField(
                            'PASSWORD', '', _passwordCtrl, null,
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password required!';
                              }
                              if (v.length < 8) return 'Min 8 characters!';
                              return null;
                            }),
                        const SizedBox(height: 14),
                        _buildTextField(
                            'CONFIRM PASSWORD', '', _confirmPasswordCtrl, null,
                            obscure: true,
                            validator: (v) {
                              if (v != _passwordCtrl.text) {
                                return 'Passwords must match!';
                              }
                              return null;
                            }),
                        const SizedBox(height: 24),
                        _btnPrimary('JOIN NOW',
                            _loading ? null : _register,
                            loading: _loading),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('BACK TO LOGIN',
                        style: DeckTheme.spaceGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: DeckColors.ink)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: DeckColors.paperDark,
            shape: BoxShape.circle,
            border: Border.all(color: DeckColors.rule, width: 2),
          ),
          child: const Center(
            child: Text('\u{1F9E0}', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Join the quiz fun!',
            style: DeckTheme.spaceGrotesk(
                fontSize: 18, color: DeckColors.ink)),
      ],
    );
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController ctrl, TextInputType? keyboardType,
      {bool obscure = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: DeckTheme.literata(fontSize: 14, color: DeckColors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isNotEmpty ? hint : null,
        labelStyle: DeckTheme.ibmPlexMono(
            fontSize: 9, color: DeckColors.graphite, letterSpacing: 0.1),
        hintStyle: DeckTheme.literata(
            fontSize: 14, color: DeckColors.graphiteFaint),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9)),
        filled: true,
        fillColor: DeckColors.paper,
      ),
      validator: validator,
    );
  }

  Widget _btnPrimary(String label, VoidCallback? onTap,
      {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: onTap != null ? DeckColors.ink : DeckColors.graphiteFaint,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: DeckColors.paper),
                  )
                : Text(label,
                    style: DeckTheme.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: DeckColors.paper)),
          ),
        ),
      ),
    );
  }
}
