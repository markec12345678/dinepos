import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/InvoiceProvider.dart';
import '../utils/const.dart';

/// Sales reports: daily sales for the last 7 days, top-selling items, and a
/// payment-method breakdown. Previously a `Placeholder()`.
class Reports extends StatelessWidget {
  const Reports({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    final invoices = invoiceProvider.invoices;
    final now = DateTime.now();

    // Daily totals for the last 7 days.
    final dailyTotals = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      double total = 0;
      for (final inv in invoices) {
        if (inv.createdAt.year == day.year &&
            inv.createdAt.month == day.month &&
            inv.createdAt.day == day.day) {
          total += inv.grandTotal;
        }
      }
      return total;
    });

    // Top selling items by quantity.
    final itemQty = <String, int>{};
    for (final inv in invoices) {
      for (final item in invoiceProvider.getItemsForInvoice(inv.id)) {
        itemQty[item.itemName] =
            (itemQty[item.itemName] ?? 0) + item.quantity;
      }
    }
    final topItems = itemQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topItems.take(5).toList();

    // Payment method breakdown.
    final methodTotals = <String, double>{};
    for (final inv in invoices) {
      methodTotals[inv.paymentType] =
          (methodTotals[inv.paymentType] ?? 0) + inv.grandTotal;
    }

    final totalRevenue =
        invoices.fold<double>(0, (s, inv) => s + inv.grandTotal);
    final totalDue =
        invoices.fold<double>(0, (s, inv) => s + (inv.dueAmount > 0 ? inv.dueAmount : 0));

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _stat('Total Revenue', '₹${totalRevenue.toStringAsFixed(2)}',
                    primaryColor),
                const SizedBox(width: 12),
                _stat('Total Due', '₹${totalDue.toStringAsFixed(2)}',
                    Colors.redAccent),
                const SizedBox(width: 12),
                _stat('Invoices', '${invoices.length}', primary2Color),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: secondaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Last 7 Days Sales',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  final day = DateTime.now()
                                      .subtract(Duration(days: 6 - value.toInt()));
                                  return Text(DateFormat('EEE').format(day),
                                      style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(7, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: dailyTotals[i],
                                  color: primaryColor,
                                  width: 16,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: secondaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Top Selling Items',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (top5.isEmpty)
                      const Text('No sales yet.')
                    else
                      ...top5.map((e) => ListTile(
                            dense: true,
                            title: Text(e.key),
                            trailing: Text('${e.value} sold'),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: secondaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Payment Methods',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (methodTotals.isEmpty)
                      const Text('No payments yet.')
                    else
                      ...methodTotals.entries.map((e) => ListTile(
                            dense: true,
                            title: Text(e.key),
                            trailing:
                                Text('₹${e.value.toStringAsFixed(2)}'),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
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
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
