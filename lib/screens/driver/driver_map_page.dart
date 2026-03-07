import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverMapPage extends StatelessWidget {
  final LatLng pickupLocation;
  final String bookingId;

  const DriverMapPage({
    super.key,
    required this.pickupLocation,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Location"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. THE MAP showing the Passenger's Pin
          FlutterMap(
            options: MapOptions(
              initialCenter: pickupLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sajilo_ride.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pickupLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 45,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. BOTTOM INFO CARD
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Passenger is waiting here",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Navigate to this location to pick up your passenger.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _confirmAcceptance(context),
                      child: const Text(
                        "ACCEPT & START NAVIGATION",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LOGIC: Final Acceptance
  Future<void> _confirmAcceptance(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride Accepted! Get moving!"), backgroundColor: Colors.green),
        );
        // After accepting, we go back to the dashboard or an "Active Trip" screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}