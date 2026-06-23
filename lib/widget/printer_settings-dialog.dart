import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../model/business_profile.dart';
import '../services/printer_service_interface.dart';
import '../utils/const.dart';

const String _lastPrinterPrefKey = 'last_used_printer_name';

/// Dialog used to scan for thermal printers and send the current invoice
/// payload to the selected device. Restaurant identity is sourced from
/// [BusinessProfileProvider]. Uses [PrinterService] so the dialog compiles
/// on platforms where `flutter_thermal_printer` is unavailable (Web, Linux);
/// on those platforms the printer list stays empty and printing is a no-op.
class PrinterSettingsDialog extends StatefulWidget {
  final List<dynamic> invoiceItems;
  final String? name;
  final String? address;
  final String phone;
  final double subtotal;
  final double discount;
  final double tax;
  final double balance;
  final double amountPaid;

  const PrinterSettingsDialog({
    super.key,
    required this.invoiceItems,
    this.name,
    this.address,
    required this.phone,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.balance,
    required this.amountPaid,
  });

  @override
  State<PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<PrinterSettingsDialog> {
  final PrinterService _service = getPrinterService();
  List<DiscoveredPrinter> printers = [];
  StreamSubscription<List<DiscoveredPrinter>>? _sub;
  bool _scanning = false;
  String? _lastPrinterName;

  @override
  void initState() {
    super.initState();
    _loadLastPrinter();
    startScan();
  }

  Future<void> _loadLastPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _lastPrinterName = prefs.getString(_lastPrinterPrefKey));
  }

  Future<void> _saveLastPrinter(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString(_lastPrinterPrefKey, name);
    } else {
      await prefs.remove(_lastPrinterPrefKey);
    }
    if (!mounted) return;
    setState(() => _lastPrinterName = name);
  }

  void startScan() {
    setState(() => _scanning = true);
    _sub?.cancel();
    _sub = _service.startScan().listen((event) {
      if (!mounted) return;
      setState(() => printers = event);
    });
    // Stop after a generous window (5s) to give slow BLE devices time.
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      stopScan();
    });
  }

  void stopScan() {
    _sub?.cancel();
    _service.stopScan();
    if (mounted) setState(() => _scanning = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProfileProvider>().profile;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _scanning
                      ? 'Scanning…'
                      : '${printers.length} devices found',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _scanning ? null : startScan,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Scan'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _scanning ? stopScan : null,
                      icon: const Icon(Icons.stop_circle_outlined, size: 18),
                      label: const Text('Stop'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(thickness: 2, color: primary2Color),
            Flexible(
              child: printers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.print_disabled,
                                size: 48, color: Colors.white54),
                            const SizedBox(height: 12),
                            const Text(
                              'No printers found.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Scan" to search, or run on Android/iOS/'
                              'Windows/macOS for thermal printer support.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: printers.length,
                      itemBuilder: (context, index) {
                        final p = printers[index];
                        final isLast = _lastPrinterName != null &&
                            p.name == _lastPrinterName;
                        return ListTile(
                          onTap: () => _print(p, business),
                          title: Text(p.name),
                          subtitle: Text(isLast
                              ? "Last used · Connected: ${p.isConnected}"
                              : "Connected: ${p.isConnected}"),
                          trailing: Icon(isLast ? Icons.star : Icons.print,
                              color: isLast ? Colors.amber : null),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _print(
      DiscoveredPrinter printer, BusinessProfile business) async {
    try {
      final profile = await CapabilityProfile.load();
      final paperSize = business.paperSizeMm == 80
          ? PaperSize.mm80
          : PaperSize.mm58;
      final generator = Generator(paperSize, profile);
      List<int> bytes = [];
      bytes += generator.text(business.restaurantName,
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2));
      if (business.address.isNotEmpty) {
        bytes += generator.text(business.address,
            styles: const PosStyles(align: PosAlign.center));
      }
      if (business.phone.isNotEmpty) {
        bytes += generator.text('Ph: ${business.phone}',
            styles: const PosStyles(align: PosAlign.center));
      }
      bytes += generator.hr();
      bytes += generator.text('Invoice To:',
          styles: const PosStyles(bold: true));
      bytes += generator.text('Name: ${widget.name ?? 'N/A'}');
      bytes += generator.text(
          'Phone: ${widget.phone.isNotEmpty ? widget.phone : 'N/A'}');
      if ((widget.address ?? '').isNotEmpty) {
        bytes += generator.text('Address: ${widget.address}');
      }
      bytes += generator.hr();
      bytes += generator.text('Item List:',
          styles: const PosStyles(bold: true));
      int serial = 1;
      for (var item in widget.invoiceItems) {
        final lineTotal = (item.price * item.quantity) as double;
        bytes += generator.text(
          '${serial.toString().padLeft(2, ' ')}  ${item.itemName}'
          '  ${item.price.toStringAsFixed(2)} x ${item.quantity}'
          ' = ${lineTotal.toStringAsFixed(2)}',
          styles: const PosStyles(align: PosAlign.left),
        );
        serial++;
      }
      bytes += generator.hr();
      bytes += generator.text(
          'Subtotal: ${business.currencySymbol}${widget.subtotal.toStringAsFixed(2)}',
          styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text(
          'Discount: ${business.currencySymbol}${widget.discount.toStringAsFixed(2)}',
          styles: const PosStyles(align: PosAlign.right));
      final base = widget.subtotal - widget.discount;
      final taxPct = base > 0 ? (widget.tax / base) * 100 : 0.0;
      bytes += generator.text('Tax: ${taxPct.toStringAsFixed(2)}%',
          styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text(
          'Paid: ${business.currencySymbol}${widget.amountPaid.toStringAsFixed(2)}',
          styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text(
          'Balance: ${business.currencySymbol}${widget.balance.toStringAsFixed(2)}',
          styles: const PosStyles(align: PosAlign.right));
      bytes += generator.emptyLines(1);
      bytes += generator.text(business.footerText,
          styles:
              const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.cut();

      await _service.printData(printer, bytes);
      await _saveLastPrinter(printer.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print job sent.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Print error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }
}
