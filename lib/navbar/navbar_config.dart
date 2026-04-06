import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/driver/driver_home_page.dart';
import 'package:sajilo_ride/screens/passenger/rides_page.dart';
import '../screens/driver/car_management.dart';
import '../screens/driver/earning.dart';
import '../screens/driver/profile.dart';
import '../screens/passenger/passenger_home_page.dart';
import '../screens/passenger/profile.dart';
import '../screens/passenger/ride_history.dart';

//To represent user roles.
enum UserRole { passenger, driver }


class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const NavItem({required this.label, required this.icon, required this.screen});
}


// Navigation items for the Passenger
 List<NavItem> passengerDestinations = [
  const NavItem(label: 'Home', icon: Icons.home, screen: PassengerHomeContent()),
  const NavItem(label: "Booking", icon: Icons.book_online_outlined, screen: MyRidesPage()),
  //const NavItem(label: 'Booking', icon: Icons.book_online_outlined,screen:BookingConfirmContent(car: null,)),
  const NavItem(label: 'History', icon: Icons.history_outlined, screen: RideHistoryContent()),
  const NavItem(label: 'Profile', icon: Icons.person_outline, screen:PassengerProfileContent()),
];

// Navigation items for the Driver
const List<NavItem> driverDestinations = [
  NavItem(label: 'Home', icon: Icons.home_outlined, screen: DriverHomeContent()),
  NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: CarManagementContent()),
  //NavItem(label: 'Booking', icon: Icons.book_online_outlined, screen: ActiveRideContent()),
  NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: DriversEarningContent()),
  NavItem(label: 'Profile', icon: Icons.person_outline, screen: DriverProfileContent()),
];


List<NavItem> getDestinationsForRole(UserRole role) {
  switch (role) {
    case UserRole.passenger:
      return passengerDestinations;
    case UserRole.driver:
      return driverDestinations;
  }
}

