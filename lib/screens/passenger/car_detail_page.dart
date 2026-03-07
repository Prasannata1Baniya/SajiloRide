import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esewa_flutter/esewa_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Add this
import 'package:latlong2/latlong.dart';       // Add this
import 'package:provider/provider.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';
import '../../auth/auth_provider.dart';

class CarDetailPage extends StatefulWidget {
  final CarModel car;
  final LatLng pickupLocation; // <--- Accept the coordinates

  const CarDetailPage({super.key, required this.car, required this.pickupLocation});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  String selectedPayment = "Cash";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car.model),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Car Image
            Image.asset(widget.car.image, height: 250, width: double.infinity, fit: BoxFit.cover),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.car.model, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      Text('\$${widget.car.pricePerHour}/hr', style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. MINI MAP SECTION
                  const Text('Pickup Point', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.pickupLocation,
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Static map
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.sajilo_ride.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: widget.pickupLocation,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _paymentOption("Cash", Icons.money),
                      const SizedBox(width: 12),
                      _paymentOption("eSewa", Icons.account_balance_wallet),
                    ],
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: selectedPayment == "eSewa" ? _buildEsewaButton() : _buildCashButton(),
        ),
      ),
    );
  }

  Widget _buildEsewaButton() {
    return EsewaPayButton(
      paymentConfig: ESewaConfig.dev(
        amt: widget.car.pricePerHour.toDouble(),
        pid: "ride_${DateTime.now().millisecondsSinceEpoch}",
        su: 'https://developer.esewa.com.np/success',
        fu: 'https://developer.esewa.com.np/failure',
      ),
      onSuccess: (result) => _saveBookingToFirestore("paid"),
      onFailure: (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: $error"))),
    );
  }

  Widget _buildCashButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: () => _saveBookingToFirestore("unpaid"),
      child: const Text("Confirm Booking (Cash)", style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Future<void> _saveBookingToFirestore(String paymentStatus) async {
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'carModel': widget.car.model,
        'price': widget.car.pricePerHour,
        'status': 'pending',
        'paymentMethod': selectedPayment,
        'paymentStatus': paymentStatus,
        'timestamp': FieldValue.serverTimestamp(),
        // SAVE ACTUAL COORDINATES HERE:
        'pickupLat': widget.pickupLocation.latitude,
        'pickupLng': widget.pickupLocation.longitude,
        'carImage': widget.car.image,
      });

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => BookingConfirmContent(car: widget.car)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _paymentOption(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}