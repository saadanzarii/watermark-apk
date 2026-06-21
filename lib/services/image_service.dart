import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../models/watermark_item.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  Future<bool> saveImageToGallery(Uint8List imageBytes, {required BuildContext context}) async {
    try {
      final bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final bool granted = await Gal.requestAccess();
        if (!granted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied.')),
            );
          }
          return false;
        }
      }

      await Gal.putImageBytes(imageBytes);
      return true;
    } catch (e) {
      debugPrint("Error saving to gallery: $e");
      return false;
    }
  }

  Future<void> shareImage(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/watermarked_image_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Check out my watermarked image!');
    } catch (e) {
      debugPrint("Error sharing image: $e");
    }
  }

  Future<Uint8List?> exportImage(File background, List<WatermarkItem> items, Size canvasSize) async {
    try {
      // 1. Decode original background image
      final bgBytes = await background.readAsBytes();
      final bgImg = img.decodeImage(bgBytes);
      if (bgImg == null) return null;

      // 2. Calculate scale factor from Canvas to Original Image
      // Ensure canvasSize is not zero
      if (canvasSize.width == 0 || canvasSize.height == 0) return null;
      
      // We assume uniform scaling (BoxFit.contain was used)
      // Actually, if it's BoxFit.contain, the canvasSize might not be the image display size!
      // The image is centered in canvasSize. We need the actual displayed image rect inside canvas.
      
      // Calculate displayed image bounds in the canvas
      final double imageAspect = bgImg.width / bgImg.height;
      final double canvasAspect = canvasSize.width / canvasSize.height;
      
      double drawWidth, drawHeight;
      double offsetX = 0, offsetY = 0;
      
      if (imageAspect > canvasAspect) {
        // Image is wider than canvas
        drawWidth = canvasSize.width;
        drawHeight = canvasSize.width / imageAspect;
        offsetY = (canvasSize.height - drawHeight) / 2;
      } else {
        // Image is taller than canvas
        drawHeight = canvasSize.height;
        drawWidth = canvasSize.height * imageAspect;
        offsetX = (canvasSize.width - drawWidth) / 2;
      }
      
      final double scaleFactor = bgImg.width / drawWidth;

      // 3. Composite each watermark onto the background
      for (final item in items) {
        // Map watermark center to image coordinates
        // The position is currently top-left, let's map top-left
        final double wmX = (item.position.dx - offsetX) * scaleFactor;
        final double wmY = (item.position.dy - offsetY) * scaleFactor;
        
        if (item.isText) {
          // Render text to image
          final wmImage = await _renderTextToImage(item, scaleFactor);
          if (wmImage != null) {
            final decodedWm = img.decodeImage(wmImage);
            if (decodedWm != null) {
              // Handle rotation. Center of rotation is the center of the watermark image
              // The text image we render doesn't include the item's rotation (we rotate it here)
              final rotatedWm = img.copyRotate(decodedWm, angle: item.rotation * 180 / 3.14159);
              
              // After rotation, image dimensions might change. We need to adjust top-left to keep center same
              final double centerX = wmX + (decodedWm.width / 2);
              final double centerY = wmY + (decodedWm.height / 2);
              
              final int drawX = (centerX - (rotatedWm.width / 2)).round();
              final int drawY = (centerY - (rotatedWm.height / 2)).round();

              img.compositeImage(bgImg, rotatedWm, dstX: drawX, dstY: drawY);
            }
          }
        } else if (item.imagePath != null) {
          final wmBytes = await File(item.imagePath!).readAsBytes();
          final decodedWm = img.decodeImage(wmBytes);
          if (decodedWm != null) {
            // Apply scale and opacity
            final int scaledWidth = (decodedWm.width * item.scale * scaleFactor).round();
            final scaledWm = img.copyResize(decodedWm, width: scaledWidth);
            
            // Apply opacity
            if (item.opacity < 1.0) {
              for (var p in scaledWm) {
                p.a = p.a * item.opacity;
              }
            }

            final rotatedWm = img.copyRotate(scaledWm, angle: item.rotation * 180 / 3.14159);
            
            final double centerX = wmX + (scaledWm.width / 2);
            final double centerY = wmY + (scaledWm.height / 2);
            
            final int drawX = (centerX - (rotatedWm.width / 2)).round();
            final int drawY = (centerY - (rotatedWm.height / 2)).round();

            img.compositeImage(bgImg, rotatedWm, dstX: drawX, dstY: drawY);
          }
        }
      }

      // 4. Encode final image
      return img.encodePng(bgImg);
    } catch (e) {
      debugPrint("Export error: $e");
      return null;
    }
  }

  Future<Uint8List?> _renderTextToImage(WatermarkItem item, double scaleFactor) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    TextStyle style;
    try {
      style = GoogleFonts.getFont(
        item.fontFamily,
        fontSize: item.fontSize * item.scale * scaleFactor, // apply both item scale and image scaleFactor
        color: item.color.withValues(alpha: item.color.a * item.opacity),
        fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: item.isItalic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: item.letterSpacing * scaleFactor,
        height: item.lineHeight,
      );
    } catch (_) {
      style = TextStyle(
        fontFamily: item.fontFamily,
        fontSize: item.fontSize * item.scale * scaleFactor,
        color: item.color.withValues(alpha: item.color.a * item.opacity),
        fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: item.isItalic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: item.letterSpacing * scaleFactor,
        height: item.lineHeight,
      );
    }

    if (item.hasShadow) {
      style = style.copyWith(
        shadows: [
          Shadow(
            offset: Offset(2.0 * scaleFactor, 2.0 * scaleFactor),
            blurRadius: 3.0 * scaleFactor,
            color: Colors.black.withValues(alpha: 0.5 * item.opacity),
          ),
        ],
      );
    }

    final textSpan = TextSpan(text: item.text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: item.textAlign,
    );

    textPainter.layout();
    
    // Create a transparent background bounding box
    final width = textPainter.width;
    final height = textPainter.height;
    
    if (width == 0 || height == 0) return null;

    textPainter.paint(canvas, Offset.zero);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
