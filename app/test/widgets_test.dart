import 'package:agent_post/core/theme/app_theme.dart';
import 'package:agent_post/core/widgets/app_card.dart';
import 'package:agent_post/core/widgets/state_views.dart';
import 'package:agent_post/features/shared/dev_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simple widget tests — no Supabase or network needed.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('AppCard renders its child', (tester) async {
    await tester.pumpWidget(wrap(const AppCard(child: Text('Hello card'))));
    expect(find.text('Hello card'), findsOneWidget);
  });

  testWidgets('LoadingView shows a spinner and message', (tester) async {
    await tester.pumpWidget(wrap(const LoadingView(message: 'Loading test…')));
    expect(find.text('Loading test…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ErrorView shows message and retry button', (tester) async {
    var retried = false;
    await tester.pumpWidget(wrap(
      ErrorView(message: 'No internet', onRetry: () => retried = true),
    ));
    expect(find.text('No internet'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('ErrorView.fromError explains offline errors in plain language',
      (tester) async {
    final view = ErrorView.fromError(Exception('SocketException: failed host lookup'));
    await tester.pumpWidget(wrap(view));
    expect(find.textContaining('No internet connection'), findsOneWidget);
  });

  testWidgets('DevPlaceholder shows the dev banner', (tester) async {
    await tester.pumpWidget(wrap(const DevPlaceholder(
      title: 'Home',
      icon: Icons.home_outlined,
    )));
    expect(find.text('DEV BUILD'), findsOneWidget);
    expect(find.textContaining('Home is under development'), findsOneWidget);
  });

  testWidgets('theme uses Material 3', (tester) async {
    expect(AppTheme.light().useMaterial3, isTrue);
  });
}
