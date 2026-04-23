import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/ui_mode_provider.dart';
import 'widgets/premium_home_view.dart';
import 'widgets/simplified_home_view.dart';

/// Hub router that switches the home visual layout between 
/// the robust classic Simplified interface and the fully animated Premium interface.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSimplified = ref.watch(uiModeProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isSimplified
          ? const SimplifiedHomeView()
          : const PremiumHomeView(),
    );
  }
}
