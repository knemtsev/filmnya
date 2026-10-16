import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../web_interop.dart';

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

  final AssetSource _startSound = AssetSource('audio/start.mp3');
  final AssetSource _agitationSound = AssetSource('audio/agitation.mp3');
  final AssetSource _stopSound = AssetSource('audio/stop.mp3');

  @override
  void initState() {
    super.initState();
    try {
      jsEnableWakeLock();
    } catch (e) {}

    _audioPlayer.setVolume(1.0);
    _startStep(DevStep.development);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    try {
      jsDisableWakeLock();
    } catch (e) {}
    super.dispose();
  }

  void _playSound(AssetSource source) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(source);
    } catch (e) {
      print("Ошибка воспроизведения аудио: $e");
    }
  }

  void _startStep(DevStep step) {
    _currentStep = step;
    _secondsElapsedInStep = 0;
    _needsAgitationRightNow = false;

    switch (step) {
      case DevStep.development:
        _secondsRemaining = widget.devTimeMinutes * 60;
        _playSound(_startSound);
        break;
      case DevStep.rinsing:
        _secondsRemaining = 1 * 60;
        _playSound(_stopSound);
        break;
      case DevStep.fixation:
        _secondsRemaining = widget.fixTimeMinutes * 60;
        _playSound(_startSound);
        break;
      case DevStep.completed:
        _secondsRemaining = 0;
        _timer?.cancel();
        _playSound(_stopSound);
        try {
          jsDisableWakeLock();
        } catch (e) {}
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
      if (mod == 0) _playSound(_agitationSound);
    } else if (widget.agitationMode == 'Каждую 1 минуту') {
      int mod = _secondsElapsedInStep % 60;
      _needsAgitationRightNow = (mod >= 0 && mod < 5);
      if (mod == 0) _playSound(_agitationSound);
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
