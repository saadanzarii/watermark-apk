import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/image_service.dart';
import '../../viewmodels/editor_viewmodel.dart';
import 'editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final imageService = ImageService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watermark Studio'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Protect your photos with custom watermarks.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image to Start', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () async {
                final file = await imageService.pickImage();
                if (file != null && context.mounted) {
                  context.read<EditorViewModel>().setBackgroundImage(file);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditorScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
