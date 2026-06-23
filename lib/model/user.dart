import 'package:hive/hive.dart';

part 'user.g.dart';

/// User role determines what features are accessible.
enum UserRole { admin, cashier, staff }

/// Application user. PINs are stored as SHA-256 hashes (never plaintext).
@HiveType(typeId: 4)
class User {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String pinHash;

  @HiveField(3)
  final String displayName;

  @HiveField(4)
  final String role; // 'admin' | 'cashier' | 'staff'

  @HiveField(5)
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.pinHash,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });

  UserRole get roleEnum => UserRole.values.firstWhere(
        (r) => r.name == role,
        orElse: () => UserRole.staff,
      );

  /// Whether this user can manage other users and settings.
  bool get isAdmin => roleEnum == UserRole.admin;

  /// Whether this user can process sales and billing.
  bool get canProcessSales => roleEnum == UserRole.admin || roleEnum == UserRole.cashier;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'pinHash': pinHash,
        'displayName': displayName,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] as num?)?.toInt() ?? 0,
        username: json['username'] as String? ?? '',
        pinHash: json['pinHash'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        role: json['role'] as String? ?? 'staff',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  User copyWith({
    int? id,
    String? username,
    String? pinHash,
    String? displayName,
    String? role,
    DateTime? createdAt,
  }) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        pinHash: pinHash ?? this.pinHash,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
      );
}
