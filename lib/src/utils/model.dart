import 'dart:typed_data';
import 'dart:ui';

class BoxModel {
  final Rect rect;
  final String label;
  final double confidence;
  final Uint8List image;

  BoxModel({
    required this.rect,
    required this.label,
    required this.confidence,
    required this.image,
  });
}
