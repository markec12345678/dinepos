import 'package:flutter/material.dart';

const primaryColor = Color(0xFF58DF94);
const primary2Color = Color(0xFFCB9DF0);
const secondary2Color = Color(0xCD404559);
const secondaryColor = Color(0xFF2A2D3E);
const bgColor = Color(0xFF212332);
const defaultPadding = 16.0;
// Currency symbol used across the app.
// NOTE: Renamed from `Symbol` to `currencySymbol` to avoid shadowing
// Dart's built-in `Symbol` core type.
const String currencySymbol = "₹";

// Backwards-compatible alias for legacy code that still references `Symbol`.
// Prefer `currencySymbol` in new code.
const String Symbol = currencySymbol;