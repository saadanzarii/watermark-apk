import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import '../../viewmodels/editor_viewmodel.dart';
import 'draggable_watermark.dart';

class InteractiveCanvas extends StatelessWidget {
  final ScreenshotController screenshotController;

  const InteractiveCanvas({
    super.key,
    required this.screenshotController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.backgroundImage == null) {
          return const Center(
            child: Text(
              'No image selected.\nTap "Select Image" to begin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            // Deselect item when tapping outside
            viewModel.selectItem(null);
          },
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.0, // Default, will be updated to image aspect ratio if possible, or just wrap
              child: Screenshot(
                controller: screenshotController,
                child: Container(
                  color: Colors.transparent, // Ensure it's captured correctly
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Background Image
                      Image.file(
                        viewModel.backgroundImage!,
                        fit: BoxFit.contain,
                      ),
                      
                      // Watermarks
                      ...viewModel.watermarkItems.map((item) {
                        return DraggableWatermark(
                          key: ValueKey(item.id),
                          item: item,
                          isSelected: item.id == viewModel.selectedItemId,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
