import 'package:flutter/material.dart';
import 'dart:math';
import 'package:yolo_realtime_plugin/yolo_realtime_plugin.dart';

class YoloBoxPainter extends CustomPainter {
  final List<BoxModel> boxes;
  final List<Color> colors;

  YoloBoxPainter({
    required this.boxes,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < boxes.length; i++) {
      final BoxModel box = boxes[i];
      final Paint paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRect(box.rect, paint);

      textPainter.text = TextSpan(
        text: '${box.label}(${box.confidence.toStringAsFixed(2)})',
        style: TextStyle(
            color: colors[i % colors.length],
            fontSize: 16,
            fontWeight: FontWeight.w500),
      );
      textPainter.layout();

      // Save the canvas state
      canvas.save();

      // Rotate the canvas
      canvas.translate(box.rect.left, box.rect.top);
      canvas.rotate(pi / 2);

      // Draw the text
      textPainter.paint(canvas, const Offset(0, 0));

      // Restore the canvas state
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
