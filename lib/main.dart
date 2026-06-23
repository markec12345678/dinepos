import 'dart:io';
import 'package:dinepos/pages/menu_items.dart';
import 'package:dinepos/pages/sale_billing.dart';
import 'package:dinepos/provider/InvoiceProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'model/business_profile.dart';
import 'model/invoice_items_model.dart';
import 'model/invoice_model.dart';
import 'model/user.dart';
import 'provider/auth_provider.dart';
import 'provider/settings_provider.dart';
import 'utils/const.dart';
import 'utils/security.dart';
import 'widget/login_screen.dart';
import 'widget/side_menu.dart';
import 'model/menuItem.dart';
import 'provider/MenuProvider.dart';

/// When `true`, the app skips authentication and starts directly on the main
/// shell. Activated by appending `?demo=1` to the URL. Used ONLY for taking
/// screenshots — always `false` in production builds.
bool get _isDemoMode => kIsWeb && Uri.base.queryParameters['demo'] == '1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Use Hive.initFlutter which handles path discovery across all platforms
    // (mobile, desktop, web). Previously we used Platform.is* checks which
    // throw on web.
    await Hive.initFlutter();

    // Register adapters before opening boxes.
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(InvoiceItemAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(InvoiceAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MenuItemAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(BusinessProfileAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(UserAdapter());

    // Open core data boxes.
    await Hive.openBox<InvoiceItem>('invoice_items');
    await Hive.openBox<Invoice>('invoices');
    await Hive.openBox<MenuItem>('menu_items');
  } catch (e) {
    debugPrint('Error initializing Hive: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MenuItemsProvider>(
          create: (_) => MenuItemsProvider()..loadMenuItems(),
        ),
        ChangeNotifierProvider<InvoiceProvider>(
          create: (_) => InvoiceProvider()..loadInvoices(),
        ),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider<BusinessProfileProvider>(
          create: (_) => BusinessProfileProvider()..init(),
        ),
      ],
      child: MaterialApp(
        title: 'DinePOS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: bgColor,
          textTheme: GoogleFonts.poppinsTextTheme(
            ThemeData.dark().textTheme,
          ).apply(bodyColor: Colors.white),
          canvasColor: secondaryColor,
          colorScheme: const ColorScheme.dark(
            primary: primaryColor,
            secondary: primary2Color,
            surface: secondaryColor,
          ),
        ),
        home: const AppRoot(),
      ),
    );
  }
}

/// Root gate: shows a loading spinner while providers initialise, the login
/// screen when no user is authenticated, or the main app shell otherwise.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final business = context.watch<BusinessProfileProvider>();

    if (!auth.isLoaded || !business.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Demo mode (URL ?demo=1) bypasses login for screenshot capture.
    if (!_isDemoMode && !auth.isAuthenticated) {
      return const LoginScreen();
    }
    return const SideMenu();
  }
}
