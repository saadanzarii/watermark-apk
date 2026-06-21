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
  double? _startScale;
  double? _startRotation;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<EditorViewModel>();

    return Positioned(
      left: widget.item.position.dx,
      top: widget.item.position.dy,
      child: Transform.rotate(
        angle: widget.item.rotation,
        child: Transform.scale(
          scale: widget.item.scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  viewModel.selectItem(widget.item.id);
                },
                onScaleStart: (details) {
                  viewModel.selectItem(widget.item.id);
                  _startScale = widget.item.scale;
                  _startRotation = widget.item.rotation;
                },
                onScaleUpdate: (details) {
                  final newScale = (_startScale! * details.scale).clamp(0.1, 10.0);
                  final newRotation = _startRotation! + details.rotation;
                  final newPosition = widget.item.position + details.focalPointDelta;

                  viewModel.updateSelectedItem(widget.item.copyWith(
                    scale: newScale,
                    rotation: newRotation,
                    position: newPosition,
                  ));
                },
                onScaleEnd: (details) {
                  viewModel.commitChanges();
                  _startScale = null;
                  _startRotation = null;
                },
                child: Container(
                  padding: const EdgeInsets.all(8.0),
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
              if (widget.isSelected)
                Positioned(
                  right: -12 / widget.item.scale,
                  bottom: -12 / widget.item.scale,
                  child: GestureDetector(
                    onPanStart: (details) {
                      _startScale = widget.item.scale;
                    },
                    onPanUpdate: (details) {
                      final newScale = (widget.item.scale + (details.delta.dy + details.delta.dx) * 0.01).clamp(0.1, 10.0);
                      viewModel.updateSelectedItem(widget.item.copyWith(scale: newScale));
                    },
                    onPanEnd: (_) => viewModel.commitChanges(),
                    child: Transform.scale(
                      scale: 1 / widget.item.scale, // Keep handle same visual size
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (widget.isSelected)
                Positioned(
                  left: -12 / widget.item.scale,
                  bottom: -12 / widget.item.scale,
                  child: GestureDetector(
                    onPanStart: (details) {
                      _startRotation = widget.item.rotation;
                    },
                    onPanUpdate: (details) {
                      final newRotation = widget.item.rotation + details.delta.dy * 0.02;
                      viewModel.updateSelectedItem(widget.item.copyWith(rotation: newRotation));
                    },
                    onPanEnd: (_) => viewModel.commitChanges(),
                    child: Transform.scale(
                      scale: 1 / widget.item.scale,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rotate_right, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
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
            color: Colors.black.withValues(alpha: 0.5),
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
