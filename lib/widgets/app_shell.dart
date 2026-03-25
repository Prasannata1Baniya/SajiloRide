import 'package:flutter/material.dart';
import '../navbar/navbar_config.dart';


class AppShell extends StatefulWidget {
  final UserRole userRole;

  const AppShell({
    super.key,
    required this.userRole,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // The list of destinations is now determined at build time.
  late List<NavItem> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = getDestinationsForRole(widget.userRole);
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 720; // Adjusted for better UX

    return Scaffold(
      body: Row(
        children: [
          //For wide screens
          if (isWide)
            NavigationRail(
              backgroundColor: Colors.orange,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Image.asset("assets/images/car_logo1.png", height: 60),
              ),
              destinations: _destinations.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon,color: Colors.white,),
                  label: Text(item.label,style: const TextStyle(color: Colors.white,)),
                );
              }).toList(),
            ),

          Expanded(
            child: _destinations[_currentIndex].screen,
          ),
        ],
      ),

      // bottom navigation mobile ko lagi
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[600],
        items: _destinations.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}