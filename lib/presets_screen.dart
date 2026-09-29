import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// Структура данных для конкретного режима (ISO, разведение, время)
class PresetOption {
  final String iso;
  final String dilution;
  final int time;

  PresetOption({required this.iso, required this.dilution, required this.time});
}

// Главная структура рецепта
class FilmPreset {
  final String filmName;
  final String developerName;
  final List<PresetOption> options;

  FilmPreset({
    required this.filmName,
    required this.developerName,
    required this.options,
  });
}

class PresetsScreen extends StatefulWidget {
  final bool isDarkroomMode;

  const PresetsScreen({super.key, required this.isDarkroomMode});

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  List<FilmPreset> _presets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresetsFromFile();
  }

  // Парсинг файла в формате: <Пленка>; <Проявитель>; <Iso1>, <разведение1>, <время1>; ...
  Future<void> _loadPresetsFromFile() async {
    try {
      final String fileContent = await rootBundle.loadString(
        'assets/presets.txt',
      );
      final List<FilmPreset> loadedPresets = [];

      for (String line in fileContent.split('\n')) {
        String trimmedLine = line.trim();
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;

        List<String> parts = trimmedLine.split(';');
        if (parts.length < 3) continue;

        String film = parts[0].trim();
        String developer = parts[1].trim();
        List<PresetOption> options = [];

        for (int i = 2; i < parts.length; i++) {
          List<String> optionParts = parts[i].split(',');
          if (optionParts.length < 3) continue;

          String iso = optionParts[0].trim();
          String dilution = optionParts[1].trim();
          // Округляем время до целых минут для простоты таймера
          double? parsedTime = double.tryParse(optionParts[2].trim());
          int time = parsedTime?.round() ?? 8;

          options.add(PresetOption(iso: iso, dilution: dilution, time: time));
        }

        if (options.isNotEmpty) {
          loadedPresets.add(
            FilmPreset(
              filmName: film,
              developerName: developer,
              options: options,
            ),
          );
        }
      }

      setState(() {
        _presets = loadedPresets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkroomMode;
    final Color redColor = const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Рецепты проявки'),
        backgroundColor: isDark ? Colors.black : Colors.blueGrey,
        foregroundColor: isDark ? redColor : Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _presets.isEmpty
          ? Center(
              child: Text(
                'Рецепты не найдены',
                style: TextStyle(color: isDark ? redColor : Colors.black),
              ),
            )
          : ListView.builder(
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                return Card(
                  color: isDark
                      ? const Color(0xFF121212)
                      : Colors.grey.shade100,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    iconColor: isDark ? redColor : Colors.blueGrey,
                    collapsedIconColor: isDark ? redColor : Colors.grey,
                    title: Text(
                      preset.filmName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? redColor : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Проявитель: ${preset.developerName}',
                      style: TextStyle(
                        color: isDark
                            ? redColor.withOpacity(0.7)
                            : Colors.grey.shade700,
                      ),
                    ),
                    children: preset.options.map((opt) {
                      return ListTile(
                        title: Text(
                          'ISO ${opt.iso} | Раствор: ${opt.dilution}',
                          style: TextStyle(
                            color: isDark ? redColor : Colors.black,
                          ),
                        ),
                        trailing: Text(
                          '${opt.time} мин',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? redColor : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          // Возвращаем выбранные данные на главный экран
                          Navigator.pop(context, {
                            'devTime': opt.time,
                            'title':
                                '${preset.filmName} (${preset.developerName}, 1:${opt.dilution})',
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
