import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'core/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MultivendorApp(),
    ),
  );
}

class MultivendorApp extends ConsumerStatefulWidget {
  const MultivendorApp({super.key});

  @override
  ConsumerState<MultivendorApp> createState() => _MultivendorAppState();
}

class _MultivendorAppState extends ConsumerState<MultivendorApp> {
  bool _hasShownStartupNotice = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ECommerce',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (!_hasShownStartupNotice) {
          _hasShownStartupNotice = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Startup Notice'),
                content: const Text(
                  'This academic showcase app may take up to 50 seconds to start because the backend can cold start.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
          });
        }

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
