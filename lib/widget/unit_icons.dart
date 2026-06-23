import 'package:flutter/material.dart';

/// Returns a representative icon for a menu item's unit type.
/// Previously returned placeholder `Text("F")`, `Text("H")` etc.
Widget getUnitIcon(String unitType, {double size = 20, Color? color}) {
  switch (unitType) {
    case 'Full':
      return Icon(Icons.dinner_dining, size: size, color: color);
    case 'Half':
      return Icon(Icons.lunch_dining, size: size, color: color);
    case 'Kg':
      return Icon(Icons.scale, size: size, color: color);
    case 'Piece':
      return Icon(Icons.cookie, size: size, color: color);
    default:
      return Icon(Icons.help_outline, size: size, color: color ?? Colors.grey);
  }
}
