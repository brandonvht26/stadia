import 'package:flutter/material.dart';
import 'package:stadia/features/my_reservations/presentation/screens/my_reservations_screen.dart';
import 'package:stadia/features/host/presentation/screens/my_receptions_screen.dart';
import 'package:stadia/features/chat/presentation/screens/inbox_screen.dart';
import 'package:stadia/features/profile/screens/profile_tab.dart';
import 'package:stadia/features/discovery/presentation/screens/discovery_screen.dart';
import 'package:stadia/core/widgets/protected_route.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const DiscoveryScreen(),
    MyReservationsScreen.route(),
    InboxScreen.route(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: Theme.of(context).colorScheme.onSurface,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explorar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Reservas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
