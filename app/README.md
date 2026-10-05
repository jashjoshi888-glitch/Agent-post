# AgentPost — Flutter app

This folder is the Android app. You do **not** need to be a developer to run it —
the plain-language instructions live in the [repository README](../README.md).

Quick version (developers):

```bash
cd app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

Tests and code checks:

```bash
flutter analyze
flutter test
```
