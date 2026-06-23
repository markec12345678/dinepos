import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart'
    as thermal;
import 'package:flutter_thermal_printer/utils/printer.dart' as thermal;

import 'printer_service_interface.dart';

/// Real [PrinterService] backed by `flutter_thermal_printer`. Used on
/// Android, iOS, macOS and Windows.
class ThermalPrinterService implements PrinterService {
  final _plugin = thermal.FlutterThermalPrinter.instance;
  StreamSubscription<List<thermal.Printer>>? _sub;

  @override
  Stream<List<DiscoveredPrinter>> startScan() {
    _plugin.getPrinters(connectionTypes: [
      thermal.ConnectionType.USB,
      thermal.ConnectionType.BLE,
    ]);
    return _plugin.devicesStream.map((event) => event
        .where((p) => p.name != null && p.name!.isNotEmpty)
        .map((p) => DiscoveredPrinter(
              name: p.name!,
              isConnected: p.isConnected ?? false,
              backendHandle: p,
            ))
        .toList());
  }

  @override
  void stopScan() {
    _sub?.cancel();
    _plugin.stopScan();
  }

  @override
  Future<void> printData(DiscoveredPrinter printer, List<int> bytes) async {
    final handle = printer.backendHandle;
    if (handle is! thermal.Printer) {
      throw ArgumentError('Invalid printer handle for ThermalPrinterService');
    }
    await _plugin.printData(handle, bytes);
  }
}
