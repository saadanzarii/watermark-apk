import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/watermark_item.dart';

class EditorViewModel extends ChangeNotifier {
  File? _backgroundImage;
  File? get backgroundImage => _backgroundImage;

  List<WatermarkItem> _watermarkItems = [];
  List<WatermarkItem> get watermarkItems => _watermarkItems;

  String? _selectedItemId;
  String? get selectedItemId => _selectedItemId;

  Size _canvasSize = Size.zero;
  Size get canvasSize => _canvasSize;

  void setCanvasSize(Size size) {
    if (_canvasSize != size) {
      _canvasSize = size;
      // notifyListeners(); // Usually not needed to rebuild on size change unless reacting to it
    }
  }

  WatermarkItem? get selectedItem {
    try {
      return _watermarkItems.firstWhere((item) => item.id == _selectedItemId);
    } catch (_) {
      return null;
    }
  }

  // History for Undo/Redo
  final List<List<WatermarkItem>> _undoHistory = [];
  final List<List<WatermarkItem>> _redoHistory = [];

  void setBackgroundImage(File image) {
    _backgroundImage = image;
    _watermarkItems.clear();
    _undoHistory.clear();
    _redoHistory.clear();
    _selectedItemId = null;
    notifyListeners();
  }

  void _saveHistory() {
    // Deep copy current items
    final currentState = _watermarkItems.map((item) => item.copyWith()).toList();
    _undoHistory.add(currentState);
    // Keep max 20 states
    if (_undoHistory.length > 20) {
      _undoHistory.removeAt(0);
    }
    _redoHistory.clear();
  }

  void undo() {
    if (_undoHistory.isNotEmpty) {
      _redoHistory.add(_watermarkItems.map((item) => item.copyWith()).toList());
      _watermarkItems = _undoHistory.removeLast();
      
      // If the selected item doesn't exist anymore, unselect
      if (_selectedItemId != null && !_watermarkItems.any((item) => item.id == _selectedItemId)) {
        _selectedItemId = null;
      }
      notifyListeners();
    }
  }

  void redo() {
    if (_redoHistory.isNotEmpty) {
      _undoHistory.add(_watermarkItems.map((item) => item.copyWith()).toList());
      _watermarkItems = _redoHistory.removeLast();
      notifyListeners();
    }
  }

  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  void addTextWatermark() {
    _saveHistory();
    final id = const Uuid().v4();
    final newItem = WatermarkItem(
      id: id,
      isText: true,
      text: 'Double tap to edit',
    );
    _watermarkItems.add(newItem);
    _selectedItemId = id;
    notifyListeners();
  }

  void addImageWatermark(String path) {
    _saveHistory();
    final id = const Uuid().v4();
    final newItem = WatermarkItem(
      id: id,
      isText: false,
      imagePath: path,
    );
    _watermarkItems.add(newItem);
    _selectedItemId = id;
    notifyListeners();
  }

  void selectItem(String? id) {
    _selectedItemId = id;
    notifyListeners();
  }

  void removeSelectedItem() {
    if (_selectedItemId != null) {
      _saveHistory();
      _watermarkItems.removeWhere((item) => item.id == _selectedItemId);
      _selectedItemId = null;
      notifyListeners();
    }
  }

  void duplicateSelectedItem() {
    final item = selectedItem;
    if (item != null) {
      _saveHistory();
      final id = const Uuid().v4();
      final newItem = item.copyWith(
        id: id,
        position: item.position + const Offset(20, 20),
      );
      _watermarkItems.add(newItem);
      _selectedItemId = id;
      notifyListeners();
    }
  }

  void updateSelectedItem(WatermarkItem newItem) {
    final index = _watermarkItems.indexWhere((item) => item.id == newItem.id);
    if (index != -1) {
      // Don't save history for continuous changes like dragging/scaling to avoid spamming history.
      // We will handle discrete history saves explicitly if needed, or periodically.
      // For simplicity, we just update the item.
      _watermarkItems[index] = newItem;
      notifyListeners();
    }
  }

  // Explicit history save for end of drag/scale/rotate gestures
  void commitChanges() {
    _saveHistory();
  }
}
