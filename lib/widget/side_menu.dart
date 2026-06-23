import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/dashboard.dart';
import '../pages/inventory.dart';
import '../pages/menu_items.dart';
import '../pages/reports.dart';
import '../pages/sale_billing.dart';
import '../pages/settings.dart';
import '../pages/user_management.dart';
import '../provider/auth_provider.dart';
import '../utils/const.dart';
import '../utils/responsive.dart';

/// Main app shell with a responsive sidebar (permanent on desktop, drawer
/// on mobile). Uses the shared [Responsive] class from `utils/responsive.dart`.
class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  late int _currentIndex = _initialPage;

  /// Reads `?page=N` from the URL (web only) for screenshot capture.
  /// Returns 0 (Dashboard) when not specified or not on web.
  static int get _initialPage {
    try {
      final p = Uri.base.queryParameters['page'];
      return p == null ? 0 : (int.tryParse(p) ?? 0);
    } catch (_) {
      return 0;
    }
  }

  static const List<Widget> _pages = [
    Dashboard(),
    SaleBilling(),
    Inventory(),
    MenuItemsScreen(),
    Reports(),
    UserManagement(),
    Settings(),
  ];

  static const List<_MenuItem> _menuItems = [
    _MenuItem(icon: Icons.home, label: 'Dashboard'),
    _MenuItem(icon: Icons.shopping_cart, label: 'Sale'),
    _MenuItem(icon: Icons.shopping_bag, label: 'Inventory'),
    _MenuItem(icon: Icons.local_dining, label: 'Items/Menu'),
    _MenuItem(icon: Icons.report, label: 'Report'),
    _MenuItem(icon: Icons.supervised_user_circle, label: 'Users'),
    _MenuItem(icon: Icons.settings, label: 'Settings'),
  ];

  void _onSelectPage(int index) {
    setState(() => _currentIndex = index);
    if (!Responsive.isDesktop(context)) Navigator.pop(context);
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
  }

  Widget _buildDrawerHeader() {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return DrawerHeader(
      decoration: const BoxDecoration(color: primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DinePOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Billing and Management System',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          const Spacer(),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.role.toUpperCase() ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuTiles() {
    return [
      for (int i = 0; i < _menuItems.length; i++)
        _buildMenuItem(_menuItems[i].icon, _menuItems[i].label, i),
    ];
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final active = _currentIndex == index;
    return InkWell(
      onTap: () => _onSelectPage(index),
      child: Container(
        decoration: BoxDecoration(
          color: active ? Colors.greenAccent.withValues(alpha: 0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(icon, color: active ? Colors.white : Colors.greenAccent),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    return Scaffold(
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: primaryColor,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              title: const Text('DinePOS'),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            SizedBox(
              width: 230,
              child: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [_buildDrawerHeader(), ..._buildMenuTiles()],
                ),
              ),
            ),
          _pages[_currentIndex],
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [_buildDrawerHeader(), ..._buildMenuTiles()],
              ),
            ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}
