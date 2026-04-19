import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lad_admin/core/auth_service.dart';

class NavigationShell extends StatelessWidget {
  final Widget child;
  const NavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;
    final String path = GoRouterState.of(context).matchedLocation;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context, path),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getSelectedIndex(path),
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Дашборд'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Заявки'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Чат'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, String path) {
    return Container(
      width: 260,
      color: const Color(0xFFF8F9F5),
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings, size: 48, color: Color(0xFF4A6741)),
                  SizedBox(height: 8),
                  Text('Lad Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          _sidebarItem(context, Icons.dashboard, 'Дашборд', '/', path == '/'),
          _sidebarItem(context, Icons.list_alt, 'Заявки', '/applications', path.startsWith('/applications')),
          _sidebarItem(context, Icons.chat, 'Чат', '/chat', path.startsWith('/chat')),
          const Spacer(),
          _sidebarItem(context, Icons.logout, 'Выйти', '/login', false, isLogout: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label, String route, bool isSelected, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF4A6741) : Colors.grey),
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF4A6741) : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onTap: () async {
        if (isLogout) {
          await AuthService.logout();
          if (context.mounted) context.go('/login');
        } else {
          context.go(route);
        }
      },
    );
  }

  int _getSelectedIndex(String path) {
    if (path == '/') return 0;
    if (path.startsWith('/applications')) return 1;
    if (path.startsWith('/chat')) return 2;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/applications'); break;
      case 2: context.go('/chat'); break;
    }
  }
}
