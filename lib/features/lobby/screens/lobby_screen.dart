import 'dart:ui';
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
    final colorScheme = Theme.of(context).colorScheme;

    return ProtectedRoute(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Fondo transparente para mostrar el de los tabs
        extendBody: true, // Extiende el cuerpo debajo de la barra para el efecto blur
        body: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.6),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent, // Transparente para que se vea el contenedor blur
                elevation: 0,
                selectedItemColor: colorScheme.primary,
                unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
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
          ),
        ),
      ),
    );
  }
}
