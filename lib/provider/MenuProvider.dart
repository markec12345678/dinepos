import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../model/menuItem.dart';

/// Provider responsible for the `menu_items` Hive box.
///
/// Acts as the single source of truth for menu items. Exposes a cached
/// in-memory list ([menuItems]) and CRUD operations that keep Hive and the
/// cache in sync.
class MenuItemsProvider with ChangeNotifier {
  late Box<MenuItem> _menuBox;

  /// In-memory cache of menu items. Kept in sync with Hive on every mutation.
  List<MenuItem> _menuItems = [];

  MenuItemsProvider() {
    _menuBox = Hive.box<MenuItem>('menu_items'); // box opened in main.dart
    loadMenuItems();
  }

  /// Getter for menu items. Returns the cached list (does NOT recompute on
  /// every access — mutations are responsible for refreshing the cache).
  List<MenuItem> get menuItems => _menuItems;

  /// Fetch menu items from Hive into the in-memory cache.
  void loadMenuItems() {
    _menuItems = _menuBox.values.toList();
    notifyListeners();
  }

  /// Generates a stable, monotonically increasing ID for a new menu item.
  /// Falls back to a timestamp-based value when the box is empty.
  int _nextId() {
    if (_menuBox.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    final maxId = _menuBox.keys.cast<int>().fold<int>(0, (a, b) => a > b ? a : b);
    return maxId + 1;
  }

  /// Add a menu item to the Hive box. If [item.id] is 0, a new auto-incremented
  /// id is assigned.
  void addMenuItem(MenuItem item) {
    final id = item.id == 0 ? _nextId() : item.id;
    final toStore = item.id == 0
        ? MenuItem(
            id: id,
            itemName: item.itemName,
            price: item.price,
            offerPrice: item.offerPrice,
            stock: item.stock,
            category: item.category,
            subCategory: item.subCategory,
            unitType: item.unitType,
            description: item.description,
            imageUrl: item.imageUrl,
            quantity: item.quantity,
          )
        : item;
    _menuBox.put(id, toStore);
    loadMenuItems();
    notifyListeners();
  }

  /// Delete a menu item by its [id]. Also removes it from the in-memory cache.
  void deleteMenuItem(int id) {
    _menuBox.delete(id);
    _menuItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Restore menu items from a backup JSON list. Replaces existing data.
  Future<void> restoreMenuItems(List<dynamic> items) async {
    try {
      if (items.isEmpty) return;
      final dataMap = <int, MenuItem>{
        for (var item in items)
          (item['id'] as int?) ?? _nextId(): MenuItem.fromJson(item as Map<String, dynamic>),
      };
      await _menuBox.putAll(dataMap);
      _menuItems = _menuBox.values.toList();
      notifyListeners();
      debugPrint('Menu items restored successfully.');
    } catch (e) {
      debugPrint('Error restoring menu items: $e');
    }
  }

  /// Update an existing menu item. All fields including [unitType] are
  /// preserved (previous versions hard-coded `unitType: ''` which lost data).
  void updateMenuItem(
    int id,
    String itemName,
    double price,
    double? offerPrice,
    int stock,
    String category,
    String? subCategory,
    String? imageUrl,
    String? description, {
    String unitType = '',
  }) {
    try {
      final existing = _menuBox.get(id);
      final updatedMenuItem = MenuItem(
        id: id,
        itemName: itemName,
        price: price,
        offerPrice: offerPrice ?? 0.0,
        stock: stock,
        category: category,
        subCategory: subCategory,
        unitType: unitType.isNotEmpty ? unitType : (existing?.unitType ?? ''),
        imageUrl: imageUrl ?? '',
        description: description,
      );
      _menuBox.put(id, updatedMenuItem);
      loadMenuItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating menu item: $e');
    }
  }

  /// Get a specific menu item by its ID. Returns a default placeholder when
  /// not found (avoids throwing in UI code).
  MenuItem getMenuItemById(int id) {
    return _menuItems.firstWhere(
      (item) => item.id == id,
      orElse: () => MenuItem(
        id: 0,
        itemName: 'Unknown',
        price: 0.0,
        offerPrice: 0.0,
        stock: 0,
        category: 'Unknown',
        subCategory: 'Unknown',
        unitType: 'Unknown',
        imageUrl: '',
      ),
    );
  }
}
