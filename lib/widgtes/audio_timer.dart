import 'dart:async';
import 'package:flutter/material.dart';

class AudioTimer extends StatefulWidget {
  final Function onTimerComplete;

  const AudioTimer({super.key, required this.onTimerComplete});

  @override
  State<AudioTimer> createState() => _AudioTimerState();
}

class _AudioTimerState extends State<AudioTimer> {
  Duration _selectedDuration = const Duration(minutes: 10);
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_selectedDuration, () {
      widget.onTimerComplete();
      setState(() => _isRunning = false);
    });
    setState(() => _isRunning = true);
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<Duration>(
          value: _selectedDuration,
          items: const [
            DropdownMenuItem(child: Text('5 min'), value: Duration(minutes: 5)),
            DropdownMenuItem(child: Text('10 min'), value: Duration(minutes: 10)),
            DropdownMenuItem(child: Text('30 min'), value: Duration(minutes: 30)),
            DropdownMenuItem(child: Text('1 hora'), value: Duration(hours: 1)),
          ],
          onChanged: _isRunning ? null : (value) {
            if (value != null) {
              setState(() => _selectedDuration = value);
            }
          },
        ),
        const SizedBox(height: 10),
        _isRunning
            ? ElevatedButton.icon(
                onPressed: _stopTimer,
                icon: const Icon(Icons.stop),
                label: const Text('Cancelar Timer'),
              )
            : ElevatedButton.icon(
                onPressed: _startTimer,
                icon: const Icon(Icons.timer),
                label: const Text('Iniciar Timer'),
              ),
      ],
    );
  }
}
