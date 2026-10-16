import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/configuration_screen.dart';

void main() {
  runApp(const FilmDeveloperApp());
}

class FilmDeveloperApp extends StatefulWidget {
  const FilmDeveloperApp({super.key});

  @override
  State<FilmDeveloperApp> createState() => _FilmDeveloperAppState();
}

class _FilmDeveloperAppState extends State<FilmDeveloperApp> {
  bool _isDarkroomMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkroomMode();
  }

  Future<void> _loadDarkroomMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkroomMode = prefs.getBool('darkroom_mode') ?? false;
    });
  }

  Future<void> _toggleDarkroomMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkroomMode = value;
    });
    await prefs.setBool('darkroom_mode', value);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _isDarkroomMode ? const Color(0xFFD32F2F) : Colors.blueGrey;
    final Color scaffoldBg = _isDarkroomMode ? Colors.black : Colors.white;
    final Color textColor = _isDarkroomMode ? const Color(0xFFD32F2F) : Colors.black;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isDarkroomMode ? Brightness.dark : Brightness.light,
    ));

    return MaterialApp(
      title: 'Проявка плёнки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: _isDarkroomMode ? Brightness.dark : Brightness.light,
          primary: primaryColor,
          surface: _isDarkroomMode ? const Color(0xFF121212) : Colors.white,
        ),
        textTheme: _isDarkroomMode
            ? TextTheme(
          bodyLarge: TextStyle(color: textColor),
          bodyMedium: TextStyle(color: textColor),
          titleLarge: TextStyle(color: textColor),
        )
            : const TextTheme(),
      ),
      home: ConfigurationScreen(
        isDarkroomMode: _isDarkroomMode,
        onDarkroomModeChanged: _toggleDarkroomMode,
      ),
    );
  }
}
