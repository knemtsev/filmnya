import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'presets_screen.dart';

void main() {
  runApp(const FilmDeveloperApp());
}

class FilmDeveloperApp extends StatelessWidget {
  const FilmDeveloperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const FilmDeveloperHome();
  }
}

class FilmDeveloperHome extends StatefulWidget {
  const FilmDeveloperHome({super.key});

  @override
  State<FilmDeveloperHome> createState() => _FilmDeveloperHomeState();
}

class _FilmDeveloperHomeState extends State<FilmDeveloperHome> {
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
    final Color primaryColor = _isDarkroomMode
        ? const Color(0xFFD32F2F)
        : Colors.blueGrey;
    final Color scaffoldBg = _isDarkroomMode ? Colors.black : Colors.white;
    final Color textColor = _isDarkroomMode
        ? const Color(0xFFD32F2F)
        : Colors.black;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkroomMode
            ? Brightness.dark
            : Brightness.light,
      ),
    );

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

// --- ЭКРАН НАСТРОЕК ---
class ConfigurationScreen extends StatefulWidget {
  final bool isDarkroomMode;
  final ValueChanged<bool> onDarkroomModeChanged;

  const ConfigurationScreen({
    super.key,
    required this.isDarkroomMode,
    required this.onDarkroomModeChanged,
  });

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  int _developmentTime = 8;
  final TextEditingController _timeController = TextEditingController(
    text: '8',
  );

  final List<String> _agitationModes = [
    'Каждые 30 секунд',
    'Каждую 1 минуту',
    'Ротационная (постоянно)',
    'Без агитации (стенд)',
  ];
  String? _selectedAgitation;

  int _fixationTime = 10;
  final TextEditingController _fixController = TextEditingController(
    text: '10',
  );

  @override
  void initState() {
    super.initState();
    _selectedAgitation = _agitationModes[0];
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _fixController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _developmentTime = prefs.getInt('dev_time') ?? 8;
      _timeController.text = _developmentTime.toString();

      _fixationTime = prefs.getInt('fix_time') ?? 10;
      _fixController.text = _fixationTime.toString();

      String? savedAgitation = prefs.getString('agitation_mode');
      if (_agitationModes.contains(savedAgitation)) {
        _selectedAgitation = savedAgitation;
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dev_time', _developmentTime);
    await prefs.setInt('fix_time', _fixationTime);
    if (_selectedAgitation != null) {
      await prefs.setString('agitation_mode', _selectedAgitation!);
    }
  }

  void _updateTimeController(int newValue) {
    if (newValue >= 1) {
      setState(() {
        _developmentTime = newValue;
        _timeController.text = _developmentTime.toString();
      });
      _saveSettings();
    }
  }

  void _updateFixationController(int newValue) {
    if (newValue >= 1) {
      setState(() {
        _fixationTime = newValue;
        _fixController.text = _fixationTime.toString();
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkroomMode;
    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isDark ? const Color(0xFFD32F2F) : Colors.black,
    );
    final inputStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: isDark ? const Color(0xFFD32F2F) : Colors.black,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка проявки'),
        centerTitle: true,
        backgroundColor: isDark
            ? Colors.black
            : Theme.of(context).colorScheme.primary,
        foregroundColor: isDark ? const Color(0xFFD32F2F) : Colors.white,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.lightbulb : Icons.lightbulb_outline),
            tooltip: 'Darkroom Mode',
            onPressed: () => widget.onDarkroomModeChanged(!isDark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- БЛОК 1: ВРЕМЯ ПРОЯВКИ ---
            Text('1. Время проявки при 20°C (мин):', style: labelStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 32,
                    color: Colors.red,
                  ),
                  onPressed: () => _updateTimeController(_developmentTime - 1),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _timeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: inputStyle,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFFD32F2F) : Colors.grey,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() => _developmentTime = parsed);
                        _saveSettings();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 32,
                    color: Colors.green,
                  ),
                  onPressed: () => _updateTimeController(_developmentTime + 1),
                ),
                const SizedBox(width: 12),
                // НОВАЯ КНОПКА ДЛЯ ВЫЗОВА ЭКРАНА ПРЕСЕТОВ
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.black
                        : Colors.blueGrey.shade100,
                    foregroundColor: isDark
                        ? const Color(0xFFD32F2F)
                        : Colors.black,
                    side: isDark
                        ? const BorderSide(color: Color(0xFFD32F2F))
                        : BorderSide.none,
                  ),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Рецепты'),
                  onPressed: () async {
                    // Переходим на экран пресетов и ждем результат
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PresetsScreen(isDarkroomMode: isDark),
                      ),
                    );

                    // Если рецепт выбран, обновляем поле времени на главном экране
                    if (result != null && result is Map) {
                      _updateTimeController(result['devTime']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Загружен рецепт: ${result['title']}'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            // --- БЛОК 2: РЕЖИМ АГИТАЦИИ ---
            Text('2. Режим агитации:', style: labelStyle),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAgitation,
              isExpanded: true,
              style: inputStyle,
              dropdownColor: isDark ? Colors.black : Colors.white,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFFD32F2F) : Colors.grey,
                  ),
                ),
              ),
              items: _agitationModes
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(
                        mode,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFD32F2F)
                              : Colors.black,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedAgitation = value);
                _saveSettings();
              },
            ),

            const SizedBox(height: 24),

            // --- БЛОК 3: ВРЕМЯ ФИКСАЦИИ ---
            Text('3. Время фиксации (мин):', style: labelStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 32,
                    color: Colors.red,
                  ),
                  onPressed: () => _updateFixationController(_fixationTime - 1),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _fixController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: inputStyle,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFFD32F2F) : Colors.grey,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() => _fixationTime = parsed);
                        _saveSettings();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 32,
                    color: Colors.green,
                  ),
                  onPressed: () => _updateFixationController(_fixationTime + 1),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- КНОПКА СТАРТ ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.black
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: isDark
                      ? const Color(0xFFD32F2F)
                      : Colors.white,
                  side: isDark
                      ? const BorderSide(color: Color(0xFFD32F2F))
                      : BorderSide.none,
                ),
                onPressed: () async {
                  await _saveSettings();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimerScreen(
                        devTimeMinutes: _developmentTime,
                        agitationMode: _selectedAgitation!,
                        fixTimeMinutes: _fixationTime,
                        isDarkroomMode: isDark,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'СТАРТ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ЭКРАН ТАЙМЕРА ---
class TimerScreen extends StatefulWidget {
  final int devTimeMinutes;
  final String agitationMode;
  final int fixTimeMinutes;
  final bool isDarkroomMode;

  const TimerScreen({
    super.key,
    required this.devTimeMinutes,
    required this.agitationMode,
    required this.fixTimeMinutes,
    required this.isDarkroomMode,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

enum DevStep { development, rinsing, fixation, completed }

class _TimerScreenState extends State<TimerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;

  DevStep _currentStep = DevStep.development;
  int _secondsRemaining = 0;
  int _totalStepSeconds = 0;

  int _secondsElapsedInStep = 0;
  bool _needsAgitationRightNow = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _startStep(DevStep.development);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _playStartSound() async {
    await _audioPlayer.play(AssetSource('audio/start.mp3'));
  }

  void _playAgitationSound() async {
    await _audioPlayer.play(AssetSource('audio/agitation.mp3'));
  }

  void _playStopSound() async {
    await _audioPlayer.play(AssetSource('audio/stop.mp3'));
  }

  void _startStep(DevStep step) {
    _currentStep = step;
    _secondsElapsedInStep = 0;
    _needsAgitationRightNow = false;

    switch (step) {
      case DevStep.development:
        _secondsRemaining = widget.devTimeMinutes * 60;
        _playStartSound();
        break;
      case DevStep.rinsing:
        _secondsRemaining = 1 * 60;
        _playStopSound();
        break;
      case DevStep.fixation:
        _secondsRemaining = widget.fixTimeMinutes * 60;
        _playStartSound();
        break;
      case DevStep.completed:
        _secondsRemaining = 0;
        _timer?.cancel();
        _playStopSound();
        WakelockPlus.disable();
        return;
    }

    _totalStepSeconds = _secondsRemaining;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          _secondsElapsedInStep++;
          _checkAgitationLogic();
        });
      } else {
        _nextStep();
      }
    });
  }

  void _checkAgitationLogic() {
    if (_currentStep != DevStep.development) {
      _needsAgitationRightNow = false;
      return;
    }

    if (_secondsElapsedInStep <= 30) {
      _needsAgitationRightNow = true;
      return;
    }

    if (widget.agitationMode == 'Каждые 30 секунд') {
      int mod = _secondsElapsedInStep % 30;
      _needsAgitationRightNow = (mod >= 0 && mod < 5);
      if (mod == 0) _playAgitationSound();
    } else if (widget.agitationMode == 'Каждую 1 минуту') {
      int mod = _secondsElapsedInStep % 60;
      _needsAgitationRightNow = (mod >= 0 && mod < 5);
      if (mod == 0) _playAgitationSound();
    } else if (widget.agitationMode == 'Ротационная (постоянно)') {
      _needsAgitationRightNow = true;
    } else {
      _needsAgitationRightNow = false;
    }
  }

  void _nextStep() {
    if (_currentStep == DevStep.development) {
      _startStep(DevStep.rinsing);
    } else if (_currentStep == DevStep.rinsing) {
      _startStep(DevStep.fixation);
    } else if (_currentStep == DevStep.fixation) {
      _startStep(DevStep.completed);
    }
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case DevStep.development:
        return 'ЭТАП 1: Проявка';
      case DevStep.rinsing:
        return 'ЭТАП 2: Слив и промывка';
      case DevStep.fixation:
        return 'ЭТАП 3: Фиксация';
      case DevStep.completed:
        return 'Процесс завершен!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkroomMode;
    final redColor = const Color(0xFFD32F2F);

    final Color agitationBg = isDark ? const Color(0xFF5D0000) : Colors.amber;
    final Color agitationText = isDark ? redColor : Colors.black;

    return Scaffold(
      backgroundColor: isDark
          ? Colors.black
          : (_needsAgitationRightNow ? Colors.amber.shade50 : Colors.white),
      appBar: AppBar(
        title: const Text('Таймер процесса'),
        backgroundColor: isDark
            ? Colors.black
            : Theme.of(context).colorScheme.primary,
        foregroundColor: isDark ? redColor : Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getStepTitle(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? redColor : Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _formatTime(_secondsRemaining),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  color: isDark ? redColor : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              if (_currentStep != DevStep.completed)
                LinearProgressIndicator(
                  value: _totalStepSeconds > 0
                      ? _secondsRemaining / _totalStepSeconds
                      : 0,
                  minHeight: 10,
                  color: isDark ? redColor : Colors.blueGrey,
                  backgroundColor: isDark
                      ? const Color(0xFF222222)
                      : Colors.grey.shade200,
                ),
              const SizedBox(height: 40),
              if (_needsAgitationRightNow &&
                  _currentStep == DevStep.development)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: agitationBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔄 АГИТАЦИЯ! Крутите бачок!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: agitationText,
                    ),
                  ),
                ),
              const SizedBox(height: 60),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.black : Colors.red,
                  foregroundColor: isDark ? redColor : Colors.white,
                  side: isDark ? BorderSide(color: redColor) : BorderSide.none,
                ),
                onPressed: () {
                  _timer?.cancel();
                  Navigator.pop(context);
                },
                child: const Text('Прервать процесс'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
