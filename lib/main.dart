// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:maze_solver/maze_solver_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setOptimalDisplayMode();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MazeSolverScreen(),
    );
  }
}

Future<void> setOptimalDisplayMode() async {
  try {
    final List<DisplayMode> modes = await FlutterDisplayMode.supported;
    if (modes.isEmpty) {
      debugPrint('Display mode adjustment is not supported on this device.');
      return;
    }

    // Log available modes for debugging
    debugPrint('Display Modes Available: ${modes.length}');
    for (final DisplayMode mode in modes) {
      debugPrint('Mode: ${mode.width}x${mode.height} @${mode.refreshRate}Hz');
    }

    // Get saved refresh rate preference
    final prefs = await SharedPreferences.getInstance();
    final int savedRefreshRate = prefs.getInt('refresh_rate') ?? 0;

    DisplayMode targetMode;
    if (savedRefreshRate > 0) {
      // Find the closest matching refresh rate
      targetMode = modes.firstWhere(
            (mode) => mode.refreshRate.round() == savedRefreshRate,
        orElse: () => modes.first,
      );
    } else {
      // No preference set, use highest refresh rate available
      targetMode = modes.reduce(
              (a, b) => a.refreshRate > b.refreshRate ? a : b
      );
    }

    await FlutterDisplayMode.setPreferredMode(targetMode);

    final DisplayMode active = await FlutterDisplayMode.active;
    debugPrint(
        'Active Mode: ${active.width}x${active.height} @${active.refreshRate}Hz');
  } catch (e) {
    debugPrint('Error setting display mode: $e');
  }
}