import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

/// App entry point:
///  1. Starts crash reporting (only when a Sentry key is configured).
///  2. Connects to Supabase.
///  3. Shows the app.
Future<void> main() async {
  // Without configuration we show a friendly explanation instead of crashing.
  if (!Env.isConfigured) {
    runApp(const ConfigMissingApp());
    return;
  }

  if (Env.sentryDsn.isEmpty) {
    // Normal development run — no crash reporting.
    await _startApp();
    return;
  }

  // Production run with crash reporting enabled.
  await SentryFlutter.init(
    (options) {
      options.dsn = Env.sentryDsn;
      options.tracesSampleRate = 0.2;
    },
    appRunner: () => runZonedGuarded(
      () async {
        await _startApp();
      },
      (error, stackTrace) {
        Sentry.captureException(error, stackTrace: stackTrace);
      },
    ),
  );
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    // PKCE is the safer sign-in flow (recommended by Supabase for mobile).
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(
    const ProviderScope(
      child: AgentPostApp(),
    ),
  );
}
