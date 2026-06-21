import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/history_service.dart';

class ImageViewerScreen extends StatelessWidget {
  final HistoryItem item;

  const ImageViewerScreen({super.key, required this.item});

  void _shareImage() {
    Share.shareXFiles([XFile(item.path)], text: 'Check out my watermarked image!');
  }

  void _deleteImage(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.errorContainer),
            onPressed: () => Navigator.pop(context, true),
            child: Text('DELETE', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final file = File(item.path);
        if (await file.exists()) {
          await file.delete();
        }
        
        // Remove from history json
        final historyService = HistoryService();
        await historyService.deleteFromHistory(item.path);
        
        if (context.mounted) {
          Navigator.pop(context); // Return to gallery
        }
      } catch (e) {
        debugPrint('Error deleting image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Hero(
        tag: 'gallery_image_${item.path}',
        child: PhotoView(
          imageProvider: FileImage(File(item.path)),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black.withValues(alpha: 0.8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareImage,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteImage(context),
            ),
          ],
        ),
      ),
    );
  }
}
