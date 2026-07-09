import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final bool obscureText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType,
    required this.controller,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword || widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      style: DeckTheme.literata(fontSize: 14, color: DeckColors.ink),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        labelStyle: DeckTheme.ibmPlexMono(
            fontSize: 9, color: DeckColors.graphite, letterSpacing: 0.1),
        hintStyle: DeckTheme.literata(
            fontSize: 14, color: DeckColors.graphiteFaint),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: DeckColors.rule)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: DeckColors.rule)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: DeckColors.blue, width: 2)),
        filled: true,
        fillColor: DeckColors.paper,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Text(
                  _obscured ? '\u{1F441}\uFE0F' : '\u{1F648}',
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
      validator: widget.validator,
    );
  }
}
