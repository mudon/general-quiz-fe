import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_header.dart';

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
            SnackBar(content: Text(msg)),
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
          SnackBar(content: Text(data['message'] ?? 'Verification sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AuthHeader(subtitle: 'Test your brainpower!'),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.outline, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 0,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _verificationMode
                          ? _buildVerificationForm()
                          : _buildLoginForm(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (!_verificationMode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outline, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            blurRadius: 0,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('New here? ', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('REGISTER 👋',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 0,
                              offset: const Offset(3, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'CREATE ACCOUNT ✨',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildLoginForm() {
    return Column(
      children: [
        AppTextField(
          label: 'EMAIL',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          controller: _emailCtrl,
          validator: (v) =>
              v == null || v.isEmpty ? 'Email required!' : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'PASSWORD',
          isPassword: true,
          controller: _passwordCtrl,
          validator: (v) =>
              v == null || v.isEmpty ? 'Password required!' : null,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/forgot-password'),
            child: const Text('Forgot password? 🤔',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary)),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _loading ? null : _login,
          child: _loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white),
                )
              : const Text('LOGIN 🚀'),
        ),
      ],
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📧', style: TextStyle(fontSize: 32)),
            SizedBox(width: 8),
            Text(
              'VERIFY EMAIL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Your email is not verified. A message with a verification code has been sent to your inbox.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _verifyTokenCtrl,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
          decoration: InputDecoration(
            labelText: 'VERIFICATION CODE',
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
            hintText: 'Paste your code here',
            hintStyle: TextStyle(
              color: AppColors.outline.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.outline, width: 2.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 3),
            ),
            filled: true,
            fillColor: AppColors.primary.withValues(alpha: 0.03),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _verifying ? null : _verifyAndLogin,
          child: _verifying
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white),
                )
              : const Text('VERIFY & LOGIN',
                  style: TextStyle(letterSpacing: 1.5)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _verifying ? null : _resendVerification,
                child: const Text('RESEND CODE',
                    style: TextStyle(fontSize: 13, letterSpacing: 1)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: _verifying ? null : _cancelVerification,
                child: const Text('BACK',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
