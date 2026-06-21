import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/editor_viewmodel.dart';
import 'draggable_watermark.dart';

class InteractiveCanvas extends StatelessWidget {
  const InteractiveCanvas({super.key});

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

        return LayoutBuilder(
          builder: (context, constraints) {
            // Store canvas size in viewmodel for precise export mapping
            WidgetsBinding.instance.addPostFrameCallback((_) {
              viewModel.setCanvasSize(Size(constraints.maxWidth, constraints.maxHeight));
            });

            return GestureDetector(
              onTap: () {
                // Deselect item when tapping outside
                viewModel.selectItem(null);
              },
              child: Container(
                color: Colors.transparent,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
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
            );
          },
        );
      },
    );
  }
}
