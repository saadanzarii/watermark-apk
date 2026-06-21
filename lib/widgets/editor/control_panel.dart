import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../common/custom_slider.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorViewModel>(
      builder: (context, viewModel, child) {
        final item = viewModel.selectedItem;

        if (item == null) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('Select a watermark to edit its properties.'),
            ),
          );
        }

        if (item.isText && _textController.text != item.text) {
          // Keep text controller in sync without causing cursor jumps
          _textController.text = item.text;
          _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
        }

        return DefaultTabController(
          length: item.isText ? 4 : 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: TabBar(
                  isScrollable: true,
                  tabs: [
                    if (item.isText) const Tab(text: 'Text'),
                    if (item.isText) const Tab(text: 'Style'),
                    const Tab(text: 'Adjust'),
                    if (item.isText) const Tab(text: 'Color'),
                  ],
                ),
              ),
              SizedBox(
                height: 250,
                child: TabBarView(
                  children: [
                    if (item.isText) _buildTextTab(viewModel),
                    if (item.isText) _buildStyleTab(viewModel),
                    _buildAdjustTab(viewModel),
                    if (item.isText) _buildColorTab(viewModel, context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextTab(EditorViewModel viewModel) {
    final item = viewModel.selectedItem!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Watermark Text',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              viewModel.updateSelectedItem(item.copyWith(text: val));
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.format_align_left),
                color: item.textAlign == TextAlign.left ? Theme.of(context).colorScheme.primary : null,
                onPressed: () => viewModel.updateSelectedItem(item.copyWith(textAlign: TextAlign.left)),
              ),
              IconButton(
                icon: const Icon(Icons.format_align_center),
                color: item.textAlign == TextAlign.center ? Theme.of(context).colorScheme.primary : null,
                onPressed: () => viewModel.updateSelectedItem(item.copyWith(textAlign: TextAlign.center)),
              ),
              IconButton(
                icon: const Icon(Icons.format_align_right),
                color: item.textAlign == TextAlign.right ? Theme.of(context).colorScheme.primary : null,
                onPressed: () => viewModel.updateSelectedItem(item.copyWith(textAlign: TextAlign.right)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyleTab(EditorViewModel viewModel) {
    final item = viewModel.selectedItem!;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToggleButtons(
              isSelected: [item.isBold, item.isItalic, item.hasShadow],
              onPressed: (index) {
                if (index == 0) viewModel.updateSelectedItem(item.copyWith(isBold: !item.isBold));
                if (index == 1) viewModel.updateSelectedItem(item.copyWith(isItalic: !item.isItalic));
                if (index == 2) viewModel.updateSelectedItem(item.copyWith(hasShadow: !item.hasShadow));
              },
              children: const [
                Icon(Icons.format_bold),
                Icon(Icons.format_italic),
                Icon(Icons.text_format), // Shadow icon proxy
              ],
            ),
          ],
        ),
        CustomSlider(
          label: 'Font Size',
          value: item.fontSize,
          min: 10,
          max: 150,
          onChanged: (val) => viewModel.updateSelectedItem(item.copyWith(fontSize: val)),
          onChangeEnd: () => viewModel.commitChanges(),
        ),
        CustomSlider(
          label: 'Spacing',
          value: item.letterSpacing,
          min: -5,
          max: 20,
          onChanged: (val) => viewModel.updateSelectedItem(item.copyWith(letterSpacing: val)),
          onChangeEnd: () => viewModel.commitChanges(),
        ),
        CustomSlider(
          label: 'Line Height',
          value: item.lineHeight,
          min: 0.5,
          max: 3.0,
          onChanged: (val) => viewModel.updateSelectedItem(item.copyWith(lineHeight: val)),
          onChangeEnd: () => viewModel.commitChanges(),
        ),
      ],
    );
  }

  Widget _buildAdjustTab(EditorViewModel viewModel) {
    final item = viewModel.selectedItem!;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        CustomSlider(
          label: 'Opacity',
          value: item.opacity,
          min: 0.0,
          max: 1.0,
          onChanged: (val) => viewModel.updateSelectedItem(item.copyWith(opacity: val)),
          onChangeEnd: () => viewModel.commitChanges(),
        ),
        CustomSlider(
          label: 'Scale',
          value: item.scale,
          min: 0.1,
          max: 10.0,
          onChanged: (val) => viewModel.updateSelectedItem(item.copyWith(scale: val)),
          onChangeEnd: () => viewModel.commitChanges(),
        ),
        CustomSlider(
          label: 'Rotation',
          value: item.rotation,
          min: -3.14159,
          max: 3.14159,
          onChanged: (val) => viewModel.updateSelectedItem(item.copyWith(rotation: val)),
          onChangeEnd: () => viewModel.commitChanges(),
        ),
      ],
    );
  }

  Widget _buildColorTab(EditorViewModel viewModel, BuildContext context) {
    final item = viewModel.selectedItem!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      Color pickerColor = item.color;
                      return AlertDialog(
                        title: const Text('Pick a color!'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: pickerColor,
                            onColorChanged: (color) {
                              pickerColor = color;
                            },
                          ),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            child: const Text('Got it'),
                            onPressed: () {
                              viewModel.updateSelectedItem(item.copyWith(color: pickerColor));
                              viewModel.commitChanges();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Pick Color'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
