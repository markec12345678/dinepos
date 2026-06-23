import 'dart:io';

import 'printer_service_interface.dart';
import 'thermal_printer_service.dart';

/// Real factory for platforms with `flutter_thermal_printer`
/// (Android, iOS, macOS, Windows).
PrinterService createPrinterService() {
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows) {
    return ThermalPrinterService();
  }
  // Linux and other desktop platforms: no thermal printer support.
  return StubPrinterService();
}
