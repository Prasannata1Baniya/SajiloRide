import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navbar/navbar_config.dart'; // Import your config

class AppShell extends StatefulWidget {
  final UserRole userRole;
  final int initialIndex;

  const AppShell({
    super.key,
    required this.userRole,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  late List<NavItem> _destinations;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // FIX: Get destinations from the central config file
    _destinations = getDestinationsForRole(widget.userRole);
    _setupPushNotifications();
  }

  void _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    String? token = await messaging.getToken();
    if (token != null) {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // FIX: Always use 'users' collection as per your AuthProvider
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.body ?? 'New Update!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              backgroundColor: Colors.black,
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedIconTheme: const IconThemeData(color: Colors.orange),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Image.asset("assets/images/SajiloRide_logo.png", height: 50),
              ),
              destinations: _destinations.map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label, style: const TextStyle(color: Colors.white)),
              )).toList(),
            ),

          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _destinations.map((item) => item.screen).toList(),
            ),
          ),
        ],
      ),

      bottomNavigationBar: isWide ? null : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white60,
        items: _destinations.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        )).toList(),
      ),
    );
  }
}


















/*import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navbar/navbar_config.dart';
import '../screens/driver/driver_home_page.dart';
import '../screens/driver/earning.dart';
import '../screens/passenger/rides_page.dart';
import '../screens/driver/car_management.dart';
import '../screens/driver/profile.dart';
import '../screens/passenger/passenger_home_page.dart';
import '../screens/passenger/profile.dart';
import '../screens/passenger/ride_history.dart';

class AppShell extends StatefulWidget {
  final UserRole userRole;
  final int initialIndex;

  const AppShell({
    super.key,
    required this.userRole,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  late List<NavItem> _destinations;
  late List<NavItem> _activeDestinations;




  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _activeDestinations = getDestinationsForRole(widget.userRole);
    _buildDestinations();
    _setupPushNotifications();
  }

  void _buildDestinations() {
    if (widget.userRole == UserRole.passenger) {
      _destinations = [
        const NavItem(label: 'Home', icon: Icons.home, screen: PassengerHomeContent()),
        const NavItem(label: "Booking", icon: Icons.book_online_outlined, screen: MyRidesPage()),
        const NavItem(label: 'History', icon: Icons.history_outlined, screen: RideHistoryContent()),
        const NavItem(label: 'Profile', icon: Icons.person_outline, screen: PassengerProfileContent()),
      ];
    } else {
      _destinations = [
        const NavItem(label: 'Home', icon: Icons.home_outlined, screen: DriverHomeContent()),
        const NavItem(label: 'Car', icon: Icons.directions_car, screen: CarManagementContent()),
        const NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: DriversEarningContent()),
        const NavItem(label: 'Profile', icon: Icons.person_outline, screen: DriverProfileContent()),
      ];
    }
  }

  void _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // fcm token
      String? token = await messaging.getToken();

      if (token != null) {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        String collection = widget.userRole == UserRole.driver ? 'drivers' : 'users';

        // Save token to Firestore
        await FirebaseFirestore.instance.collection(collection).doc(uid).update({
          'fcmToken': token,
        });
        debugPrint("FCM Token Saved: $token");
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Notification: ${message.notification?.body ?? 'New Request!'}"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive check: Sidebar for Web/Tablet (> 720px), BottomBar for Mobile
    final bool isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
     /* body: Row(
        children: [
          // Sidebar for Wide Screens (Web)
          if (isWide)
            NavigationRail(
              backgroundColor: Colors.orange.shade800,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Image.asset("assets/images/SajiloRide_logo.png", height: 50),
              ),
              destinations: _destinations.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),

          // Main Content
          Expanded(
            child: _destinations[_currentIndex].screen,
          ),
        ],
      ),

      // Bottom Navigation for Mobile
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
      ),*/
      body: Row(
        children: [
          if(isWide)
            NavigationRail(
              selectedIndex: _currentIndex,
              backgroundColor: Colors.black,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Image.asset("assets/images/SajiloRide_logo.png", height: 50),
              ),
              destinations: _activeDestinations.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                );
              }).toList(),
            ),

          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _activeDestinations.map((item) => item.screen).toList(),
            ),
          ),
        ],
      ),
      // Bottom NAVBAR for Mobile
      bottomNavigationBar: isWide
          ? null
          : Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.black,
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.white60,
          items: _activeDestinations.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
        ),
      ),


    );
  }
}
*/