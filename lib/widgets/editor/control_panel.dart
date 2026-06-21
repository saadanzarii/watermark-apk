import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../common/custom_slider.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final _textController = TextEditingController();

  final List<String> _popularFonts = [
    'Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Oswald',
    'Raleway', 'Merriweather', 'Nunito', 'Playfair Display',
    'Ubuntu', 'Poppins', 'Inter', 'Dancing Script', 'Pacifico'
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showFontPicker(BuildContext context, EditorViewModel viewModel) {
    final item = viewModel.selectedItem;
    if (item == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Font', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _popularFonts.length,
                itemBuilder: (context, index) {
                  final font = _popularFonts[index];
                  return ListTile(
                    title: Text(
                      font,
                      style: GoogleFonts.getFont(font, fontSize: 18),
                    ),
                    trailing: item.fontFamily == font ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () {
                      viewModel.updateSelectedItem(item.copyWith(fontFamily: font));
                      viewModel.commitChanges();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
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
          _textController.text = item.text;
          _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
        }

        return DefaultTabController(
          length: item.isText ? 4 : 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    if (item.isText) _buildTextTab(viewModel, context),
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

  Widget _buildTextTab(EditorViewModel viewModel, BuildContext context) {
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
              OutlinedButton.icon(
                icon: const Icon(Icons.font_download),
                label: Text(item.fontFamily),
                onPressed: () => _showFontPicker(context, viewModel),
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
                Icon(Icons.text_format),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ColorPicker(
        color: item.color,
        onColorChanged: (Color color) {
          viewModel.updateSelectedItem(item.copyWith(color: color));
        },
        onColorChangeEnd: (Color color) {
          viewModel.commitChanges();
        },
        heading: Text('Select color', style: Theme.of(context).textTheme.titleMedium),
        subheading: Text('Select color shade', style: Theme.of(context).textTheme.titleMedium),
        pickersEnabled: const <ColorPickerType, bool>{
          ColorPickerType.both: false,
          ColorPickerType.primary: true,
          ColorPickerType.accent: true,
          ColorPickerType.bw: false,
          ColorPickerType.custom: true,
          ColorPickerType.wheel: true,
        },
      ),
    );
  }
}
