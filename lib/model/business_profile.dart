import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../utils/security.dart';

part 'business_profile.g.dart';

/// Editable business identity used across the app (receipts, invoices,
/// printer output, UPI QR codes). Previously these values were hard-coded
/// throughout the UI; this model externalises them so they can be configured
/// from the Settings screen.
///
/// Persisted to a Hive box named `business_profile` keyed by a single
/// integer key `0` (singleton profile).
@HiveType(typeId: 3)
class BusinessProfile {
  @HiveField(0)
  final String restaurantName;

  @HiveField(1)
  final String address;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  /// UPI Virtual Payment Address, e.g. `merchant@okbizaxis`.
  final String upiId;

  @HiveField(4)
  /// Payee name embedded in the UPI deep link (`pn` field).
  final String payeeName;

  @HiveField(5)
  /// Merchant category code (`mc` field in the UPI deep link).
  final String merchantCode;

  @HiveField(6)
  /// Footer text printed at the bottom of receipts.
  final String footerText;

  @HiveField(7)
  /// Thermal paper width: `58` or `80` (mm).
  final int paperSizeMm;

  @HiveField(8)
  /// Currency symbol used on receipts and in the UI.
  final String currencySymbol;

  @HiveField(9)
  /// Default tax rate (%) applied to new invoices.
  final double defaultTaxRatePercent;

  const BusinessProfile({
    required this.restaurantName,
    required this.address,
    required this.phone,
    required this.upiId,
    required this.payeeName,
    required this.merchantCode,
    required this.footerText,
    required this.paperSizeMm,
    required this.currencySymbol,
    required this.defaultTaxRatePercent,
  });

  /// Sensible defaults so the app works out-of-the-box before the user
  /// configures their own profile.
  factory BusinessProfile.defaults() => const BusinessProfile(
        restaurantName: 'DinePOS Restaurant',
        address: '',
        phone: '',
        upiId: '',
        payeeName: 'DinePOS',
        merchantCode: '',
        footerText: 'Thank You, Visit Again!',
        paperSizeMm: 58,
        currencySymbol: '₹',
        defaultTaxRatePercent: 0,
      );

  /// Builds a UPI deep-link string for the given amount.
  /// Format: `upi://pay?pa=<upiId>&am=<amount>&pn=<payeeName>&mc=<merchantCode>`
  String upiDeepLink(double amount) {
    if (upiId.isEmpty) return '';
    final params = <String, String>{
      'pa': upiId,
      'am': amount.toStringAsFixed(2),
      'pn': payeeName,
      if (merchantCode.isNotEmpty) 'mc': merchantCode,
      'cu': 'INR',
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'upi://pay?$query';
  }

  BusinessProfile copyWith({
    String? restaurantName,
    String? address,
    String? phone,
    String? upiId,
    String? payeeName,
    String? merchantCode,
    String? footerText,
    int? paperSizeMm,
    String? currencySymbol,
    double? defaultTaxRatePercent,
  }) =>
      BusinessProfile(
        restaurantName: restaurantName ?? this.restaurantName,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        upiId: upiId ?? this.upiId,
        payeeName: payeeName ?? this.payeeName,
        merchantCode: merchantCode ?? this.merchantCode,
        footerText: footerText ?? this.footerText,
        paperSizeMm: paperSizeMm ?? this.paperSizeMm,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        defaultTaxRatePercent:
            defaultTaxRatePercent ?? this.defaultTaxRatePercent,
      );

  Map<String, dynamic> toJson() => {
        'restaurantName': restaurantName,
        'address': address,
        'phone': phone,
        'upiId': upiId,
        'payeeName': payeeName,
        'merchantCode': merchantCode,
        'footerText': footerText,
        'paperSizeMm': paperSizeMm,
        'currencySymbol': currencySymbol,
        'defaultTaxRatePercent': defaultTaxRatePercent,
      };

  factory BusinessProfile.fromJson(Map<String, dynamic> json) =>
      BusinessProfile(
        restaurantName: json['restaurantName'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        upiId: json['upiId'] as String? ?? '',
        payeeName: json['payeeName'] as String? ?? 'DinePOS',
        merchantCode: json['merchantCode'] as String? ?? '',
        footerText: json['footerText'] as String? ?? 'Thank You, Visit Again!',
        paperSizeMm: (json['paperSizeMm'] as num?)?.toInt() ?? 58,
        currencySymbol: json['currencySymbol'] as String? ?? '₹',
        defaultTaxRatePercent:
            (json['defaultTaxRatePercent'] as num?)?.toDouble() ?? 0,
      );
}

/// ChangeNotifier wrapper around the singleton [BusinessProfile] Hive box.
class BusinessProfileProvider extends ChangeNotifier {
  static const String _boxName = 'business_profile';
  static const int _profileKey = 0;

  BusinessProfile _profile = BusinessProfile.defaults();
  bool _loaded = false;

  BusinessProfile get profile => _profile;
  bool get isLoaded => _loaded;

  /// Opens the box and loads the profile (or seeds defaults on first run).
  Future<void> init() async {
    try {
      final box = await Hive.openBox<BusinessProfile>(_boxName,
          encryptionCipher: HiveAesCipher(AppSecurity.hiveKey()));
      final stored = box.get(_profileKey);
      if (stored != null) {
        _profile = stored;
      } else {
        await box.put(_profileKey, _profile);
      }
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('BusinessProfileProvider.init error: $e');
      _loaded = true;
    }
  }

  /// Persists [profile] and notifies listeners.
  Future<void> save(BusinessProfile profile) async {
    final box = Hive.box<BusinessProfile>(_boxName);
    _profile = profile;
    await box.put(_profileKey, profile);
    notifyListeners();
  }
}
