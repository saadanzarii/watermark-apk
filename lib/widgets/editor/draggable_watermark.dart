import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/watermark_item.dart';
import '../../viewmodels/editor_viewmodel.dart';

class DraggableWatermark extends StatefulWidget {
  final WatermarkItem item;
  final bool isSelected;

  const DraggableWatermark({
    super.key,
    required this.item,
    required this.isSelected,
  });

  @override
  State<DraggableWatermark> createState() => _DraggableWatermarkState();
}

class _DraggableWatermarkState extends State<DraggableWatermark> {
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<EditorViewModel>();

    return Positioned(
      left: widget.item.position.dx,
      top: widget.item.position.dy,
      child: GestureDetector(
        onTap: () {
          viewModel.selectItem(widget.item.id);
        },
        onScaleStart: (details) {
          viewModel.selectItem(widget.item.id);
          _baseScale = widget.item.scale;
          _baseRotation = widget.item.rotation;
          _basePosition = widget.item.position;
        },
        onScaleUpdate: (details) {
          final newScale = (_baseScale * details.scale).clamp(0.1, 10.0);
          final newRotation = _baseRotation + details.rotation;
          final newPosition = _basePosition + details.focalPoint - details.localFocalPoint;

          // Update position taking into account pan delta.
          // Wait, focalPointDelta is easier.
          final currentPos = widget.item.position;
          
          final newItem = widget.item.copyWith(
            scale: newScale,
            rotation: newRotation,
            position: currentPos + details.focalPointDelta,
          );
          viewModel.updateSelectedItem(newItem);
        },
        onScaleEnd: (details) {
          viewModel.commitChanges();
        },
        child: Transform.rotate(
          angle: widget.item.rotation,
          child: Transform.scale(
            scale: widget.item.scale,
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                border: widget.isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2 / widget.item.scale)
                    : Border.all(color: Colors.transparent, width: 2 / widget.item.scale),
              ),
              child: Opacity(
                opacity: widget.item.opacity,
                child: widget.item.isText ? _buildText() : _buildImage(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    TextStyle style;
    try {
      style = GoogleFonts.getFont(
        widget.item.fontFamily,
        fontSize: widget.item.fontSize,
        color: widget.item.color,
        fontWeight: widget.item.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: widget.item.isItalic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: widget.item.letterSpacing,
        height: widget.item.lineHeight,
      );
    } catch (_) {
      // Fallback
      style = TextStyle(
        fontFamily: widget.item.fontFamily,
        fontSize: widget.item.fontSize,
        color: widget.item.color,
        fontWeight: widget.item.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: widget.item.isItalic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: widget.item.letterSpacing,
        height: widget.item.lineHeight,
      );
    }

    if (widget.item.hasShadow) {
      style = style.copyWith(
        shadows: [
          Shadow(
            offset: const Offset(2.0, 2.0),
            blurRadius: 3.0,
            color: Colors.black.withOpacity(0.5),
          ),
        ],
      );
    }

    return Text(
      widget.item.text,
      textAlign: widget.item.textAlign,
      style: style,
    );
  }

  Widget _buildImage() {
    if (widget.item.imagePath != null) {
      return Image.file(
        File(widget.item.imagePath!),
        fit: BoxFit.contain,
      );
    }
    return const SizedBox();
  }
}
