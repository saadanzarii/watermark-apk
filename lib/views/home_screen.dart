import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/image_service.dart';
import '../../services/history_service.dart';
import '../../viewmodels/editor_viewmodel.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImageService _imageService = ImageService();
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _recentExports = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.loadHistory();
    setState(() {
      _recentExports = history;
    });
  }

  void _openEditor(File file) {
    if (mounted) {
      context.read<EditorViewModel>().setBackgroundImage(file);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditorScreen()),
      ).then((_) => _loadHistory()); // Reload history when returning
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watermark Studio'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.water_drop,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Protect your photos with custom watermarks.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select Image to Start', style: TextStyle(fontSize: 18)),
                      onPressed: () async {
                        final file = await _imageService.pickImage();
                        if (file != null) {
                          _openEditor(file);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_recentExports.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text(
                  'Recent Exports',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _recentExports[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          // Allow re-editing or viewing
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(item.path),
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _recentExports.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
}
