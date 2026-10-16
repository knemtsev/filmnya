import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presets_screen.dart';
import 'timer_screen.dart';

const String appVersion = 'v1.2.0 (2026-10-16_12-55-46)';

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
            onPressed: () => widget.onDarkroomModeChanged(!isDark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PresetsScreen(isDarkroomMode: isDark),
                      ),
                    );
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
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Версия: $appVersion',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFFD32F2F).withOpacity(0.5)
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
