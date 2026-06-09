import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_state.dart';
import 'data/calendar_store.dart';
import 'data/repository_provider.dart';
import 'data/session_store.dart';
import 'data/settings_store.dart';
import 'data/sqflite/app_database.dart';
import 'data/workout_store.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Open the SQLite database and hydrate all in-memory stores before rendering.
  final db = await AppDatabase.open();
  final repos = RepositoryProvider.fromDatabase(db);

  await SettingsStore.instance.hydrate(repos.settings);
  await WorkoutStore.instance.hydrate(repos.routines);
  await CalendarStore.instance.hydrate(repos.schedule);
  await SessionStore.instance.hydrate(repos.sessions);

  runApp(const FlexFlowApp());
}

class FlexFlowApp extends StatelessWidget {
  const FlexFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'FlexFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
