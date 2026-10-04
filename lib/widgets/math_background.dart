import 'package:flutter/material.dart';
import 'dart:math' as math;

class MathBackground extends StatelessWidget {
  final Widget child;

  const MathBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Background gradient (static, non-interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F2847),
                      Color(0xFF1A3A52),
                      Color(0xFF0D1F35),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Custom paint for mathematical elements (static, non-interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: MathElementsPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          // Main content
          child,
        ],
      ),
    );
  }
}

class MathElementsPainter extends CustomPainter {
  final math.Random _random = math.Random(42); // Fixed seed for consistency

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const mathSymbols = [
      '×',
      '÷',
      '√',
      '∑',
      '∫',
      '≈',
      '≠',
      '∞',
      'π',
      'α',
      'β',
      'θ',
      '∂',
      '∇',
      '±',
      '≤',
      '≥',
    ];

    // Draw scattered mathematical symbols
    for (int i = 0; i < 25; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height * 0.8; // Keep symbols away from bottom

      // Skip if too close to center (where content usually is)
      if (x > size.width * 0.3 && x < size.width * 0.7 &&
          y > size.height * 0.2 && y < size.height * 0.8) {
        continue;
      }

      final symbol = mathSymbols[i % mathSymbols.length];
      final fontSize = 12.0 + _random.nextDouble() * 20;

      textPainter.text = TextSpan(
        text: symbol,
        style: TextStyle(
          color: const Color(0xFF42A5F5).withValues(alpha: 0.5 + _random.nextDouble() * 0.3),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    // Draw decorative dots
    for (int i = 0; i < 15; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      final dotPaint = Paint()
        ..color = const Color(0xFF42A5F5).withValues(alpha: 0.6 + _random.nextDouble() * 0.4)
        ..style = PaintingStyle.fill;

      final radius = 2.0 + _random.nextDouble() * 3;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);

      // Draw connecting lines between some dots
      if (i % 3 == 0 && i < 14) {
        final nextX = _random.nextDouble() * size.width;
        final nextY = _random.nextDouble() * size.height;

        canvas.drawLine(
          Offset(x, y),
          Offset(nextX, nextY),
          paint..strokeWidth = 0.8,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MathElementsPainter oldDelegate) => false;
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A5F).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const double waveHeight = 30;
    const double waveLength = 100;

    Path path1 = Path();
    path1.moveTo(0, size.height * 0.4);

    for (double i = 0; i <= size.width; i += 10) {
      final double y = size.height * 0.4 +
          waveHeight * math.sin((i / waveLength) * 2 * math.pi);
      if (i == 0) {
        path1.lineTo(i, y);
      } else {
        path1.lineTo(i, y);
      }
    }

    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    canvas.drawPath(path1, paint..color = const Color(0xFF0D47A1).withValues(alpha: 0.3));

    // Second wave (offset)
    Path path2 = Path();
    path2.moveTo(0, size.height * 0.55);

    for (double i = 0; i <= size.width; i += 10) {
      final double y = size.height * 0.55 +
          waveHeight * 0.7 * math.sin((i / waveLength) * 2 * math.pi + math.pi / 4);
      if (i == 0) {
        path2.lineTo(i, y);
      } else {
        path2.lineTo(i, y);
      }
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint..color = const Color(0xFF1565C0).withValues(alpha: 0.4));

    // Wave lines (strokes only)
    Path waveLine1 = Path();
    waveLine1.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i += 10) {
      final double y = size.height * 0.5 +
          waveHeight * 0.5 * math.sin((i / waveLength) * 2 * math.pi);
      if (i == 0) {
        waveLine1.lineTo(i, y);
      } else {
        waveLine1.lineTo(i, y);
      }
    }

    canvas.drawPath(waveLine1, paint..color = const Color(0xFF42A5F5).withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => false;
}
