import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthService authService;

  const ForgotPasswordScreen({super.key, required this.authService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _resetStage = false;
  bool _done = false;

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final message = await widget.authService.forgotPassword(
        email: _emailCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _resetStage = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _doReset() async {
    if (_tokenCtrl.text.trim().isEmpty || _newPasswordCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid token and new password (min 8 chars).')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final message = await widget.authService.resetPassword(
        token: _tokenCtrl.text.trim(),
        newPassword: _newPasswordCtrl.text,
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _done = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPasswordCtrl.dispose();
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
                  _buildHeader(),
                  const SizedBox(height: 36),
                  if (_done)
                    _buildDoneCard()
                  else if (_resetStage)
                    _buildResetCard()
                  else
                    _buildEmailCard(),
                  const SizedBox(height: 24),
                  if (!_done)
                    _buildBackButton(),
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
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline, width: 3),
            boxShadow: [
              BoxShadow(
                color: _done
                    ? AppColors.success.withValues(alpha: 0.4)
                    : AppColors.secondary.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _done ? AppColors.successBg : AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _done ? '✅' : _resetStage ? '🔐' : '🔑',
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _done
              ? 'PASSWORD RESET!'
              : _resetStage
                  ? 'SET NEW PASSWORD'
                  : 'FORGOT PASSWORD?',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _done
              ? 'Your password has been changed.\nYou can now log in.'
              : _resetStage
                  ? 'Enter the token sent to your email\nand choose a new password.'
                  : 'No worries! Enter your email\nand we\'ll send a reset token.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailCard() {
    return Container(
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
        child: Column(
          children: [
            AppTextField(
              label: 'EMAIL',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              controller: _emailCtrl,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Email required!' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _sendReset,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shadowColor: AppColors.secondary.withValues(alpha: 0.5),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white),
                    )
                  : const Text('SEND TOKEN 📩'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetCard() {
    return Container(
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
        child: Column(
          children: [
            TextField(
              controller: _tokenCtrl,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                labelText: 'RESET TOKEN',
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
                hintText: 'Paste the token from your email',
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
            const SizedBox(height: 16),
            AppTextField(
              label: 'NEW PASSWORD',
              isPassword: true,
              controller: _newPasswordCtrl,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password required!';
                if (v.length < 8) return 'Min 8 characters!';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _doReset,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white),
                    )
                  : const Text('RESET PASSWORD 🔒'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneCard() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            const Text(
              'ALL DONE!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your email is now verified.\nLog in with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.success,
                shadowColor: Colors.white.withValues(alpha: 0.3),
              ),
              child: const Text('BACK TO LOGIN',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        if (_resetStage) {
          setState(() => _resetStage = false);
        } else {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 2.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👈 '),
            Text(
              _resetStage ? 'EDIT EMAIL' : 'BACK TO LOGIN',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
