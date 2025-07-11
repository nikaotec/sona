import 'package:flutter/material.dart';
import 'dart:math';

class WaveformVisualizer extends StatelessWidget {
  final List<int> waveData;

  const WaveformVisualizer({super.key, required this.waveData});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(waveData),
      size: Size.infinite,
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<int> waveData;

  _WaveformPainter(this.waveData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final midY = size.height / 2;
    final step = size.width / waveData.length;

    path.moveTo(0, midY);
    for (int i = 0; i < waveData.length; i++) {
      final x = i * step;
      final y = midY - (waveData[i] - 128).toDouble() * size.height / 256;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
