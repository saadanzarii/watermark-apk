import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../services/image_service.dart';
import '../../services/history_service.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../widgets/editor/interactive_canvas.dart';
import '../widgets/editor/control_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ImageService _imageService = ImageService();
  final HistoryService _historyService = HistoryService();
  bool _isExporting = false;

  void _exportImage(bool share) async {
    final viewModel = context.read<EditorViewModel>();
    
    // Deselect before export to remove bounding boxes visually (though exportImage doesn't render them)
    viewModel.selectItem(null);
    
    setState(() {
      _isExporting = true;
    });

    try {
      if (viewModel.backgroundImage == null) return;

      final imageBytes = await _imageService.exportImage(
        viewModel.backgroundImage!,
        viewModel.watermarkItems,
        viewModel.canvasSize,
      );
      
      if (imageBytes != null) {
        if (share) {
          await _imageService.shareImage(imageBytes);
        } else {
          // Save to Local History
          await _historyService.saveImageToLocalDirectory(imageBytes, viewModel.backgroundImage!.path);
          // Save to Device Gallery
          final success = await _imageService.saveImageToGallery(imageBytes, context: context);
          
          if (mounted) {
            toastification.show(
              context: context,
              title: const Text('Export Successful'),
              description: Text(success ? 'Image saved to gallery and history.' : 'Image saved to history.'),
              type: ToastificationType.success,
              style: ToastificationStyle.flatColored,
              autoCloseDuration: const Duration(seconds: 3),
              alignment: Alignment.bottomCenter,
            );
            Navigator.pop(context); // Return to home screen
          }
        }
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Export Failed'),
          description: const Text('An error occurred during export.'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter,
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
              const Expanded(
                child: InteractiveCanvas(),
              ),
              const Divider(height: 1),
              _buildBottomToolbar(context),
              Consumer<EditorViewModel>(
                builder: (context, viewModel, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: viewModel.selectedItemId != null ? 300 : 0,
                    child: const SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(),
                      child: ControlPanel(),
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
          if (viewModel.selectedItemId != null) ...[
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.blue),
              onPressed: () {
                viewModel.duplicateSelectedItem();
                toastification.show(
                  context: context,
                  title: const Text('Watermark duplicated'),
                  type: ToastificationType.info,
                  autoCloseDuration: const Duration(seconds: 2),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => viewModel.removeSelectedItem(),
            ),
          ]
        ],
      ),
    );
  }
}
