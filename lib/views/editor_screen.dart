import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import '../../services/image_service.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../widgets/editor/interactive_canvas.dart';
import '../widgets/editor/control_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImageService _imageService = ImageService();
  bool _isExporting = false;

  void _exportImage(bool share) async {
    final viewModel = context.read<EditorViewModel>();
    
    // Deselect before screenshot to remove bounding boxes
    viewModel.selectItem(null);
    
    setState(() {
      _isExporting = true;
    });

    try {
      // Small delay to allow UI to update and remove selection borders
      await Future.delayed(const Duration(milliseconds: 100));
      
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0); // High quality
      
      if (imageBytes != null) {
        if (share) {
          await _imageService.shareImage(imageBytes);
        } else {
          final success = await _imageService.saveImageToGallery(imageBytes, context: context);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? 'Saved to gallery!' : 'Failed to save.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during export.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _pickImageWatermark() async {
    final file = await _imageService.pickImage();
    if (file != null && mounted) {
      context.read<EditorViewModel>().addImageWatermark(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watermark Studio'),
        actions: [
          Consumer<EditorViewModel>(
            builder: (context, viewModel, child) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: viewModel.canUndo ? () => viewModel.undo() : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: viewModel.canRedo ? () => viewModel.redo() : null,
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isExporting ? null : () => _exportImage(true),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isExporting ? null : () => _exportImage(false),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: InteractiveCanvas(
                  screenshotController: _screenshotController,
                ),
              ),
              const Divider(height: 1),
              _buildBottomToolbar(context),
              Consumer<EditorViewModel>(
                builder: (context, viewModel, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: viewModel.selectedItemId != null ? 300 : 0,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: const ControlPanel(),
                    ),
                  );
                },
              ),
            ],
          ),
          if (_isExporting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(BuildContext context) {
    final viewModel = context.watch<EditorViewModel>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.title),
            label: const Text('Add Text'),
            onPressed: () => viewModel.addTextWatermark(),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.image),
            label: const Text('Add Image'),
            onPressed: _pickImageWatermark,
          ),
          if (viewModel.selectedItemId != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => viewModel.removeSelectedItem(),
            ),
        ],
      ),
    );
  }
}
