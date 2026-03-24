import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A text field that appears softly "carved" into a glass panel.
class PremiumInput extends StatelessWidget {
  const PremiumInput({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.textInputAction,
  });

  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        // Inset shadow emulating a "carved" look
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            offset: Offset(2, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color(0x30FFFFFF),
            offset: Offset(-1, -1),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
              : null,
        ),
      ),
    );
  }
}
