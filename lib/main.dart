import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/settings/app_lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the local Isar database before the app starts rendering so that
  // every screen can assume `isarProvider` is ready -- no loading branches
  // needed deep in the widget tree. This is the one deliberately-awaited
  // async step in an otherwise offline-first, no-login app.
  final isar = await openAppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const FinanceTrackerApp(),
    ),
  );
}

class FinanceTrackerApp extends ConsumerStatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  ConsumerState<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends ConsumerState<FinanceTrackerApp> {
  bool _themeSyncedFromSettings = false;

  @override
  void initState() {
    super.initState();
    // Guarantees the single-row SettingsModel exists so settingsStreamProvider
    // (watchObject(0)) has something to emit from the very first frame.
    Future.microtask(() => ref.read(settingsRepositoryProvider).getOrCreate());
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // One-time sync: once the persisted SettingsModel loads, apply its
    // saved theme choice. After that, the in-memory themeModeProvider is
    // the source of truth for the rest of the session (Settings screen
    // writes to both).
    ref.listen(settingsStreamProvider, (previous, next) {
      final settings = next.value;
      if (settings == null || _themeSyncedFromSettings) return;
      _themeSyncedFromSettings = true;
      final mode = switch (settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      Future.microtask(() => ref.read(themeModeProvider.notifier).setThemeMode(mode));
    });

    return MaterialApp(
      title: 'My Personal Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
      builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
