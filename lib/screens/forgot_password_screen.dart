import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

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
          SnackBar(
              content: Text(message,
                  style: DeckTheme.ibmPlexMono(
                      color: DeckColors.paper, fontSize: 10))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''),
                  style: DeckTheme.ibmPlexMono(
                      color: DeckColors.paper, fontSize: 10))),
        );
      }
    }
  }

  Future<void> _doReset() async {
    if (_tokenCtrl.text.trim().isEmpty || _newPasswordCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Enter a valid token and new password (min 8 chars).',
                style: DeckTheme.ibmPlexMono(
                    color: DeckColors.paper, fontSize: 10))),
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
          SnackBar(
              content: Text(message,
                  style: DeckTheme.ibmPlexMono(
                      color: DeckColors.paper, fontSize: 10))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''),
                  style: DeckTheme.ibmPlexMono(
                      color: DeckColors.paper, fontSize: 10))),
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
                  if (_done)
                    _buildDoneCard()
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: DeckColors.paper,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _resetStage
                          ? _buildResetCard()
                          : _buildEmailCard(),
                    ),
                  const SizedBox(height: 20),
                  if (!_done) _buildBackButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final emoji = _done
        ? '\u2705'
        : _resetStage
            ? '\u{1F510}'
            : '\u{1F511}';
    final title = _done
        ? 'PASSWORD RESET!'
        : _resetStage
            ? 'SET NEW PASSWORD'
            : 'FORGOT PASSWORD?';
    final sub = _done
        ? 'Your password has been changed.\nYou can now log in.'
        : _resetStage
            ? 'Enter the token sent to your email\nand choose a new password.'
            : 'No worries! Enter your email\nand we\'ll send a reset token.';

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _done ? DeckColors.greenFaint : DeckColors.paperDark,
            shape: BoxShape.circle,
            border: Border.all(
                color: _done ? DeckColors.green : DeckColors.rule,
                width: 2),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: DeckTheme.spaceGrotesk(
                fontSize: 18, color: DeckColors.ink)),
        const SizedBox(height: 6),
        Text(sub,
            textAlign: TextAlign.center,
            style: DeckTheme.literata(
                fontSize: 13,
                color: DeckColors.graphite,
                height: 1.4)),
      ],
    );
  }

  Widget _buildEmailCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField('EMAIL', 'you@example.com', _emailCtrl,
            TextInputType.emailAddress,
            validator: (v) =>
                v == null || v.isEmpty ? 'Email required!' : null),
        const SizedBox(height: 20),
        _btnPrimary('SEND TOKEN', _loading ? null : _sendReset,
            loading: _loading),
      ],
    );
  }

  Widget _buildResetCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _tokenCtrl,
          style: DeckTheme.literata(fontSize: 14, color: DeckColors.ink),
          decoration: InputDecoration(
            labelText: 'RESET TOKEN',
            hintText: 'Paste the token from your email',
            labelStyle: DeckTheme.ibmPlexMono(
                fontSize: 9,
                color: DeckColors.graphite,
                letterSpacing: 0.1),
            hintStyle: DeckTheme.literata(
                fontSize: 14, color: DeckColors.graphiteFaint),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9)),
            filled: true,
            fillColor: DeckColors.paper,
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
            'NEW PASSWORD', '', _newPasswordCtrl, null,
            obscure: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password required!';
              if (v.length < 8) return 'Min 8 characters!';
              return null;
            }),
        const SizedBox(height: 20),
        _btnPrimary('RESET PASSWORD', _loading ? null : _doReset,
            loading: _loading),
      ],
    );
  }

  Widget _buildDoneCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DeckColors.greenFaint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeckColors.green),
      ),
      child: Column(
        children: [
          const Text('\u{1F389}', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text('ALL DONE!',
              style: DeckTheme.spaceGrotesk(
                  fontSize: 16, color: DeckColors.green)),
          const SizedBox(height: 16),
          _btnPrimary(
              'BACK TO LOGIN', () => Navigator.pop(context)),
        ],
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
      child:       Text(
        _resetStage ? 'EDIT EMAIL' : 'BACK TO LOGIN',
        style: DeckTheme.spaceGrotesk(
            fontSize: 13.5, color: DeckColors.ink),
      ),
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
