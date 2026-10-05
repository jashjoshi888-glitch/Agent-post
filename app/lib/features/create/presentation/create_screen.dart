import 'package:flutter/material.dart';

import '../../shared/dev_placeholder.dart';

/// Create tab — the Social Media Studio arrives in a later phase.
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevPlaceholder(
      title: 'Create',
      icon: Icons.add_photo_alternate_outlined,
    );
  }
}
