import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/InvoiceProvider.dart';
import '../../utils/const.dart';

/// Pie chart showing the payment-method breakdown (Cash / UPI / Other) of
/// all-time invoice totals. Previously displayed fake "29.1 of 128GB"
/// template data.
class Chart extends StatelessWidget {
  const Chart({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().invoices;
    double cash = 0, upi = 0, other = 0;
    for (final inv in invoices) {
      final t = inv.grandTotal;
      if (inv.paymentType == 'Cash') {
        cash += t;
      } else if (inv.paymentType == 'UPI') {
        upi += t;
      } else {
        other += t;
      }
    }
    final total = cash + upi + other;

    final sections = <PieChartSectionData>[
      if (cash > 0)
        PieChartSectionData(
          color: primaryColor,
          value: cash,
          title: 'Cash',
          showTitle: false,
          radius: 28,
        ),
      if (upi > 0)
        PieChartSectionData(
          color: const Color(0xFF26E5FF),
          value: upi,
          title: 'UPI',
          showTitle: false,
          radius: 24,
        ),
      if (other > 0)
        PieChartSectionData(
          color: const Color(0xFFFFCF26),
          value: other,
          title: 'Other',
          showTitle: false,
          radius: 20,
        ),
    ];

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              startDegreeOffset: -90,
              sections: sections.isEmpty
                  ? [
                      PieChartSectionData(
                        color: Colors.white.withValues(alpha: 0.1),
                        value: 1,
                        showTitle: false,
                        radius: 20,
                      ),
                    ]
                  : sections,
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  total > 0 ? '₹${total.toStringAsFixed(0)}' : '—',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Total Sales',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
