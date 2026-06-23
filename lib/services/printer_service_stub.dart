import 'printer_service_interface.dart';

/// Stub factory for platforms without `flutter_thermal_printer` (Web, Linux).
PrinterService createPrinterService() => StubPrinterService();
