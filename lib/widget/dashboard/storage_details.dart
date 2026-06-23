import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/InvoiceProvider.dart';
import '../../utils/const.dart';
import 'chart.dart';

/// Side-panel summary shown on the dashboard. Previously displayed fake
/// "1.3GB / 1328 Files" template data; now shows real sales metrics derived
/// from the invoice provider.
class StorageDetails extends StatelessWidget {
  const StorageDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().invoices;
    final now = DateTime.now();

    double todaySales = 0;
    double cashSales = 0;
    double upiSales = 0;
    double yearlySales = 0;
    for (final inv in invoices) {
      final total = inv.grandTotal;
      if (inv.createdAt.year == now.year) {
        yearlySales += total;
        if (inv.createdAt.month == now.month &&
            inv.createdAt.day == now.day) {
          todaySales += total;
        }
      }
      if (inv.paymentType == 'Cash') {
        cashSales += total;
      } else if (inv.paymentType == 'UPI') {
        upiSales += total;
      }
    }

    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sales Breakdown",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: defaultPadding),
          // Payment-method pie chart (cash vs UPI vs other).
          SizedBox(
            height: 160,
            child: Chart(),
          ),
          StorageInfoCard(
            icon: Icons.today,
            title: "Today's Sales",
            amount: '₹${todaySales.toStringAsFixed(2)}',
            subtitle: '${invoices.where((i) => i.createdAt.day == now.day && i.createdAt.month == now.month && i.createdAt.year == now.year).length} invoices',
          ),
          StorageInfoCard(
            icon: Icons.attach_money,
            title: "Cash Sales",
            amount: '₹${cashSales.toStringAsFixed(2)}',
            subtitle: 'All time',
          ),
          StorageInfoCard(
            icon: Icons.qr_code,
            title: "UPI Sales",
            amount: '₹${upiSales.toStringAsFixed(2)}',
            subtitle: 'All time',
          ),
          StorageInfoCard(
            icon: Icons.calendar_today,
            title: "This Year",
            amount: '₹${yearlySales.toStringAsFixed(2)}',
            subtitle: '${now.year}',
          ),
        ],
      ),
    );
  }
}

class StorageInfoCard extends StatelessWidget {
  const StorageInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.amount,
    required this.subtitle,
  });

  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: defaultPadding),
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: primaryColor.withValues(alpha: 0.15)),
        borderRadius: const BorderRadius.all(
          Radius.circular(defaultPadding),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
