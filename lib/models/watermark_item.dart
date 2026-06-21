import 'package:flutter/material.dart';

enum PatternType {
  single,
  grid,
  staggered,
}

class WatermarkItem {
  final String id;
  
  // Content
  final bool isText;
  String text;
  String? imagePath;
  
  // Position & Transform
  Offset position;
  double scale;
  double rotation; // In radians
  
  // Text Styling
  Color color;
  double opacity;
  String fontFamily;
  double fontSize;
  double letterSpacing;
  double lineHeight;
  bool isBold;
  bool isItalic;
  bool hasShadow;
  TextAlign textAlign;

  // Pattern settings
  PatternType patternType;
  double patternSpacingX;
  double patternSpacingY;

  WatermarkItem({
    required this.id,
    required this.isText,
    this.text = '',
    this.imagePath,
    this.position = const Offset(100, 100),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = Colors.black,
    this.opacity = 1.0,
    this.fontFamily = 'Roboto',
    this.fontSize = 24.0,
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.isBold = false,
    this.isItalic = false,
    this.hasShadow = false,
    this.textAlign = TextAlign.center,
    this.patternType = PatternType.single,
    this.patternSpacingX = 50.0,
    this.patternSpacingY = 50.0,
  });

  WatermarkItem copyWith({
    String? id,
    bool? isText,
    String? text,
    String? imagePath,
    Offset? position,
    double? scale,
    double? rotation,
    Color? color,
    double? opacity,
    String? fontFamily,
    double? fontSize,
    double? letterSpacing,
    double? lineHeight,
    bool? isBold,
    bool? isItalic,
    bool? hasShadow,
    TextAlign? textAlign,
    PatternType? patternType,
    double? patternSpacingX,
    double? patternSpacingY,
  }) {
    return WatermarkItem(
      id: id ?? this.id,
      isText: isText ?? this.isText,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      hasShadow: hasShadow ?? this.hasShadow,
      textAlign: textAlign ?? this.textAlign,
      patternType: patternType ?? this.patternType,
      patternSpacingX: patternSpacingX ?? this.patternSpacingX,
      patternSpacingY: patternSpacingY ?? this.patternSpacingY,
    );
  }
}
