import 'package:flutter/material.dart';

import '../../shared/dev_placeholder.dart';

/// Home tab — the "What should I post today?" dashboard arrives in a later
/// phase. For now it shows the developer placeholder.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevPlaceholder(
      title: 'Home',
      icon: Icons.dashboard_outlined,
    );
  }
}
