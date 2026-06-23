import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'printer_service_stub.dart'
    if (dart.library.io) 'printer_service_io.dart';

/// Conditional factory for [PrinterService].
///
/// On platforms supported by `flutter_thermal_printer` (Android, iOS, macOS,
/// Windows) the real implementation is used. On unsupported platforms
/// (Linux, Web) a no-op stub is used so the rest of the app still compiles
/// and runs.
PrinterService getPrinterService() => createPrinterService();

abstract class PrinterService {
  /// Start scanning for printers. Returns a stream that emits discovered
  /// printer lists. Empty list means no devices found yet.
  Stream<List<DiscoveredPrinter>> startScan();

  /// Stop an in-progress scan.
  void stopScan();

  /// Sends [bytes] (ESC/POS payload) to [printer].
  Future<void> printData(DiscoveredPrinter printer, List<int> bytes);
}

/// Minimal, platform-agnostic description of a discovered printer.
class DiscoveredPrinter {
  final String name;
  final bool isConnected;
  final dynamic backendHandle; // opaque handle used by the backend

  const DiscoveredPrinter({
    required this.name,
    required this.isConnected,
    this.backendHandle,
  });
}

/// Fallback used on Web and Linux.
class StubPrinterService implements PrinterService {
  @override
  Stream<List<DiscoveredPrinter>> startScan() async* {
    await Future.delayed(const Duration(milliseconds: 100));
    yield [];
  }

  @override
  void stopScan() {}

  @override
  Future<void> printData(DiscoveredPrinter printer, List<int> bytes) async {
    debugPrint('StubPrinterService: printing is not supported on this platform.');
  }
}
