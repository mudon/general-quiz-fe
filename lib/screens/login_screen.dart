import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _verifyTokenCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _verifying = false;
  bool _verificationMode = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.authService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('not verified') || msg.contains('403')) {
          setState(() {
            _verificationMode = true;
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(msg,
                    style: DeckTheme.ibmPlexMono(
                        color: DeckColors.paper, fontSize: 10))),
          );
        }
      }
    }
  }

  Future<void> _resendVerification() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _verifying = true);
    try {
      final data = await widget.authService.resendVerification(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ?? 'Verification sent',
                  style: DeckTheme.ibmPlexMono(
                      color: DeckColors.paper, fontSize: 10))),
        );
      }
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
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _verifyAndLogin() async {
    final token = _verifyTokenCtrl.text.trim();
    if (token.isEmpty) return;
    setState(() => _verifying = true);
    try {
      await widget.authService.verifyEmail(token: token);
      await _login();
    } catch (e) {
      if (mounted) {
        setState(() => _verifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''),
                  style: DeckTheme.ibmPlexMono(
                      color: DeckColors.paper, fontSize: 10))),
        );
      }
    }
  }

  void _cancelVerification() {
    setState(() {
      _verificationMode = false;
      _verifyTokenCtrl.clear();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _verifyTokenCtrl.dispose();
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
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: DeckColors.paper,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _verificationMode
                        ? _buildVerificationForm()
                        : _buildLoginForm(),
                  ),
                  const SizedBox(height: 24),
                  if (!_verificationMode) ...[
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/register'),
                    child: Text('CREATE ACCOUNT \u2728',
                        style: DeckTheme.spaceGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: DeckColors.ink)),
                    ),
                  ],
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
        Text('Quiz Deck',
            style: DeckTheme.spaceGrotesk(
                fontSize: 24, color: DeckColors.ink)),
        const SizedBox(height: 4),
        Text('Test your brainpower!',
            style: DeckTheme.ibmPlexMono(
                fontSize: 10, color: DeckColors.graphite)),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField('EMAIL', 'you@example.com', _emailCtrl,
            TextInputType.emailAddress,
            validator: (v) =>
                v == null || v.isEmpty ? 'Email required!' : null),
        const SizedBox(height: 14),
        _buildTextField('PASSWORD', '', _passwordCtrl, null,
            obscure: true,
            validator: (v) =>
                v == null || v.isEmpty ? 'Password required!' : null),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, '/forgot-password'),
            child: Text('Forgot password?',
                style: DeckTheme.ibmPlexMono(
                    fontSize: 9,
                    color: DeckColors.blue)),
          ),
        ),
        const SizedBox(height: 16),
        _btnPrimary('LOGIN', _loading ? null : _login, loading: _loading),
      ],
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\u{1F4E7}', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('VERIFY EMAIL',
                style: DeckTheme.spaceGrotesk(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your email is not verified. A verification code has been sent to your inbox.',
          textAlign: TextAlign.center,
          style: DeckTheme.literata(
              fontSize: 13, color: DeckColors.graphite, height: 1.4),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _verifyTokenCtrl,
          textInputAction: TextInputAction.done,
          style: DeckTheme.literata(fontSize: 14, color: DeckColors.ink),
          decoration: InputDecoration(
            labelText: 'VERIFICATION CODE',
            hintText: 'Paste your code here',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9)),
            filled: true,
            fillColor: DeckColors.paper,
          ),
        ),
        const SizedBox(height: 14),
        _btnPrimary('VERIFY & LOGIN',
            _verifying ? null : _verifyAndLogin,
            loading: _verifying),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _btnOutline(
                  'RESEND CODE',
                  _verifying ? null : _resendVerification),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _cancelVerification,
                child: Center(
                  child: Text('BACK',
                      style: DeckTheme.ibmPlexMono(
                          fontSize: 10, color: DeckColors.graphite)),
                ),
              ),
            ),
          ],
        ),
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

  Widget _btnOutline(String label, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: onTap != null ? DeckColors.ink : DeckColors.graphiteFaint,
                width: 1.5),
          ),
          child: Center(
            child: Text(label,
                style: DeckTheme.spaceGrotesk(
                    fontSize: 13.5, color: DeckColors.ink)),
          ),
        ),
      ),
    );
  }
}
