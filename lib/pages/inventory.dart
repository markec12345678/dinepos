import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/MenuProvider.dart';
import '../utils/const.dart';

/// Inventory view: shows menu items with stock levels and low-stock alerts.
/// Previously a `Placeholder()`.
class Inventory extends StatelessWidget {
  const Inventory({super.key});

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuItemsProvider>();
    final items = menuProvider.menuItems;
    final lowStock = items.where((i) => i.stock <= 5).toList();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _statCard('Total Items', '${items.length}', primaryColor),
                  const SizedBox(width: 12),
                  _statCard(
                      'Low Stock', '${lowStock.length}', Colors.orangeAccent),
                  const SizedBox(width: 12),
                  _statCard(
                    'Out of Stock',
                    '${items.where((i) => i.stock == 0).length}',
                    Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Stock Levels',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Expanded(
                  child: Center(child: Text('No menu items. Add items first.')),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: items.map((item) {
                        final status = item.stock == 0
                            ? 'Out of stock'
                            : item.stock <= 5
                                ? 'Low'
                                : 'OK';
                        final statusColor = item.stock == 0
                            ? Colors.red
                            : item.stock <= 5
                                ? Colors.orange
                                : Colors.green;
                        return DataRow(cells: [
                          DataCell(Text(item.itemName)),
                          DataCell(Text(item.category)),
                          DataCell(Text(item.unitType)),
                          DataCell(Text('${item.stock}')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(status,
                                style: const TextStyle(color: Colors.white)),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
