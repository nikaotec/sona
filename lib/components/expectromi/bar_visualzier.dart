import 'package:flutter/material.dart';
import 'dart:math';

class BarVisualizer extends StatelessWidget {
  final List<int> waveData;

  const BarVisualizer({super.key, required this.waveData});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarVisualizerPainter(waveData),
      size: Size.infinite,
    );
  }
}

class _BarVisualizerPainter extends CustomPainter {
  final List<int> waveData;
  _BarVisualizerPainter(this.waveData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final barCount = waveData.length;
    final barWidth = size.width / barCount;
    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth;
      final barHeight = waveData[i] * size.height / 255;
      final y = size.height - barHeight;
      canvas.drawLine(Offset(x, size.height), Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}