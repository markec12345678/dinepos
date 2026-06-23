import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/invoice_items_model.dart';
import '../model/invoice_model.dart';

/// Provider responsible for the `invoices` and `invoice_items` Hive boxes.
///
/// Keeps in-memory caches in sync with Hive and provides helpers for
/// cascading deletes (deleting an invoice also deletes its line items).
class InvoiceProvider with ChangeNotifier {
  late final Box<Invoice> _invoiceBox;
  late final Box<InvoiceItem> _invoiceItemBox;

  InvoiceProvider() {
    _invoiceBox = Hive.box<Invoice>('invoices');
    _invoiceItemBox = Hive.box<InvoiceItem>('invoice_items');
    loadInvoices();
    loadInvoiceItems();
  }

  final List<Invoice> _invoices = [];
  final List<InvoiceItem> _invoiceItems = [];

  /// Cached list of invoices.
  List<Invoice> get invoices => _invoices;

  /// Cached list of all invoice items (across all invoices).
  List<InvoiceItem> get invoiceItems => _invoiceItems;

  /// Reload invoices from Hive into the cache.
  void loadInvoices() {
    _invoices
      ..clear()
      ..addAll(_invoiceBox.values.toList());
    notifyListeners();
  }

  /// Reload invoice items from Hive into the cache.
  void loadInvoiceItems() {
    _invoiceItems
      ..clear()
      ..addAll(_invoiceItemBox.values.toList());
    notifyListeners();
  }

  /// Fetch items belonging to a specific invoice.
  List<InvoiceItem> getItemsForInvoice(int invoiceId) {
    final invoiceIdStr = invoiceId.toString();
    return _invoiceItems
        .where((item) => item.invoiceId == invoiceIdStr)
        .toList();
  }

  /// Generates a stable, monotonically increasing ID for a new invoice.
  int _nextId() {
    if (_invoiceBox.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    final keys = _invoiceBox.keys;
    int maxId = 0;
    for (final k in keys) {
      if (k is int && k > maxId) maxId = k;
    }
    return maxId + 1;
  }

  /// Generates a stable, monotonically increasing ID for a new invoice item.
  int _nextItemId() {
    if (_invoiceItemBox.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    final keys = _invoiceItemBox.keys;
    int maxId = 0;
    for (final k in keys) {
      if (k is int && k > maxId) maxId = k;
    }
    return maxId + 1;
  }

  /// Add an invoice. If [invoice.id] is 0, a new auto-incremented id is used.
  void addInvoice(Invoice invoice) {
    if (!_invoiceBox.isOpen) return;
    final id = invoice.id == 0 ? _nextId() : invoice.id;
    final toStore = invoice.id == 0
        ? Invoice(
            id: id,
            userId: invoice.userId,
            name: invoice.name,
            phone: invoice.phone,
            address: invoice.address,
            status: invoice.status,
            subtotal: invoice.subtotal,
            discount: invoice.discount,
            taxRate: invoice.taxRate,
            amountPaid: invoice.amountPaid,
            paymentType: invoice.paymentType,
            createdAt: invoice.createdAt,
          )
        : invoice;
    _invoiceBox.put(id, toStore);
    loadInvoices();
    notifyListeners();
  }

  /// Add an invoice item. If [invoiceItem.id] is null, an auto-incremented id
  /// is assigned.
  void addInvoiceItem(InvoiceItem invoiceItem) {
    if (!_invoiceItemBox.isOpen) return;
    final id = invoiceItem.id ?? _nextItemId();
    final toStore = InvoiceItem(
      id: id,
      invoiceId: invoiceItem.invoiceId,
      itemName: invoiceItem.itemName,
      quantity: invoiceItem.quantity,
      price: invoiceItem.price,
      total: invoiceItem.total,
    );
    _invoiceItemBox.put(id, toStore);
    loadInvoiceItems();
    notifyListeners();
  }

  /// Restore invoices from a backup JSON list.
  Future<void> restoreInvoices(List<dynamic> invoices) async {
    try {
      if (invoices.isEmpty) return;
      final dataMap = <int, Invoice>{
        for (var invoice in invoices)
          (invoice['id'] as int?) ?? 0: Invoice.fromJson(invoice as Map<String, dynamic>),
      };
      await _invoiceBox.putAll(dataMap);
      _invoices
        ..clear()
        ..addAll(_invoiceBox.values.toList());
      notifyListeners();
      debugPrint('Invoices restored successfully.');
    } catch (e) {
      debugPrint('Error restoring invoices: $e');
    }
  }

  /// Restore invoice items from a backup JSON list.
  Future<void> restoreInvoiceItems(List<dynamic> invoiceItems) async {
    try {
      if (invoiceItems.isEmpty) return;
      final dataMap = <int, InvoiceItem>{
        for (var item in invoiceItems)
          (item['id'] as int?) ?? 0: InvoiceItem.fromJson(item as Map<String, dynamic>),
      };
      await _invoiceItemBox.putAll(dataMap);
      _invoiceItems
        ..clear()
        ..addAll(_invoiceItemBox.values.toList());
      notifyListeners();
      debugPrint('Invoice items restored successfully.');
    } catch (e) {
      debugPrint('Error restoring invoice items: $e');
    }
  }

  /// Delete an invoice **and** all of its line items (cascading delete).
  void deleteInvoice(int id) {
    if (!_invoiceBox.isOpen) return;
    _invoiceBox.delete(id);
    // Cascade: remove orphan invoice items belonging to this invoice.
    final invoiceIdStr = id.toString();
    final orphanKeys = <int>[];
    for (final entry in _invoiceItemBox.toMap().entries) {
      final item = entry.value;
      if (item.invoiceId == invoiceIdStr) {
        orphanKeys.add(entry.key as int);
      }
    }
    for (final key in orphanKeys) {
      _invoiceItemBox.delete(key);
    }
    loadInvoices();
    loadInvoiceItems();
    notifyListeners();
  }

  /// Delete a single invoice item by its id.
  void deleteInvoiceItem(int id) {
    if (!_invoiceItemBox.isOpen) return;
    _invoiceItemBox.delete(id);
    loadInvoiceItems();
    notifyListeners();
  }
}
