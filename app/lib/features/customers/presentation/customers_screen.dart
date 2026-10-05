import 'package:flutter/material.dart';

import '../../shared/dev_placeholder.dart';

/// Customers tab — the CRM (leads + customers) arrives in a later phase.
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevPlaceholder(
      title: 'Customers',
      icon: Icons.people_outline_rounded,
    );
  }
}
