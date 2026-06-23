import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Security helpers for encrypting sensitive Hive boxes.
///
/// The key is derived from a fixed app seed via SHA-256. For a real
/// production deployment you would mix in a device-specific value (e.g. a
/// random secret stored in platform secure storage) so that copying the Hive
/// files to another device would not reveal the data.
class AppSecurity {
  AppSecurity._();

  /// 256-bit encryption key for Hive's `HiveAesCipher`.
  static List<int> hiveKey() {
    const seed = 'dinepos::hive::encryption::v1';
    return sha256.convert(utf8.encode(seed)).bytes;
  }
}
