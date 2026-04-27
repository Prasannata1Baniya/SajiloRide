
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:sajilo_ride/core/constants/payment_config.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';
import 'package:sajilo_ride/screens/passenger/car_driver_detail.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../navbar/navbar_config.dart';


class PassengerHomeContent extends StatefulWidget {
  const PassengerHomeContent({super.key});

  @override
  State<PassengerHomeContent> createState() => _PassengerHomeContentState();
}

class _PassengerHomeContentState extends State<PassengerHomeContent> {
  final MapController _mapController = MapController();

  LatLng _currentCenter = const LatLng(27.7172, 85.3240);
  LatLng? pickupLocation;
  LatLng? dropOffLocation;
  List<LatLng> routePoints = [];

  double distance = 0;
  double fare = 0;
  CarModel? selectedCar;
  String selectedPayment = "Cash";

  String _pickupAddress = "Select Pickup Point";
  String _dropoffAddress = "Select Drop-off Point";
  bool isSelectingPickup = true;

  List<CarModel> liveCars = [];

  // Fallback Data
  final List<CarModel> carList = [
    CarModel(model: 'Sajilo Moto', carNumber: 'BA 1 PA 1234',
        image:  "assets/images/car1.jpg", driverId: 'demo1',
        driverName: 'Sajilo Pilot',  phone: '9800000000',
        vehicleType: 'Sajilo Moto', pricePerKm: 0,
        rating: 5, isOnline: true,
        latitude: 2.3, longitude: 23)
  ];
  /*final List<CarModel> carList = [
    CarModel(model: "Sajilo Moto", distance: 0, pricePerHour: 20,
        fuelCapacity: 0, image: "assets/images/car1.jpg", driverId: 'demo1',
        carNumber: '', driverName: '', phone: ''),
    CarModel(model: "Sajilo Car", distance: 0, pricePerHour: 50,
        fuelCapacity: 0, image: "assets/images/car2.jpg", driverId: 'demo2',
        carNumber: '', driverName: '', phone: ''),
  ];*/

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
 }

  Future<void> _getCurrentLocation() async {
    // 1. Handle Permissions First
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // User has permanently denied, you might want to show a SnackBar
        if (!mounted) return;

        // 2. Show the SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permissions are permanently denied. Please enable them in settings.'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                // 3. Open the actual App Settings on the phone
                Geolocator.openAppSettings();
              },
            ),
          ),
        );
        return;
      }
    }

    try {
      // 2. Get high-accuracy position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final current = LatLng(position.latitude, position.longitude);

      setState(() {
        pickupLocation = current;
        _currentCenter = current; // Syncs the map center
      });

      // 3. Update the Map UI
      _mapController.move(current, 15);

      // 4. Convert coordinates to a readable name for the UI
      await _getAddress(current, true);

    } catch (e) {
      debugPrint("Location error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not fetch location. Please pick manually."))
        );
      }
    }
  }

  void _updateLocationState(LatLng pos, bool isPickup) {
    setState(() {
      if (isPickup) {
        pickupLocation = pos;
      } else{
        dropOffLocation = pos;
      }
    });

    if (pickupLocation != null && dropOffLocation != null) {
      // Zoom out to show both markers
      final bounds = LatLngBounds.fromPoints([pickupLocation!, dropOffLocation!]);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
      _getRoute();
    } else {
      _mapController.move(pos, 14);
    }
    _getAddress(pos, isPickup);
  }

  /*void _updateLocationState(LatLng pos, bool isPickup) {
    setState(() {
      if (isPickup) {
        pickupLocation = pos;
        _currentCenter = pos;
      } else {
        dropOffLocation = pos;
      }});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(pos, 14);
    });
    _getAddress(pos, isPickup);
    if (pickupLocation != null && dropOffLocation != null) _getRoute();

  }*/

  Future<void> _getAddress(LatLng position, bool isPickup) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');
      final response = await http.get(url, headers: {'User-Agent': 'com.prasannata.sajilo_ride'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (isPickup) {
            _pickupAddress = data['display_name'] ?? "Current Location";
          } else {
            _dropoffAddress = data['display_name'] ?? "Target Location";
          }
        });
      }
    } catch (e) { debugPrint("Geo Error: $e"); }
  }

  Future<void> _getRoute() async {
    final url = Uri.parse("https://router.project-osrm.org/route/v1/driving/${pickupLocation!.longitude}"
        ",${pickupLocation!.latitude};${dropOffLocation!.longitude},${dropOffLocation!.latitude}"
        "?overview=full&geometries=geojson");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List;
        if (routes.isEmpty) return;
        final coords = routes[0]['geometry']['coordinates'];
        setState(() {
          routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          distance = routes[0]['distance'] / 1000.0;
          if (selectedCar != null) fare = distance * selectedCar!.pricePerKm;
        });
      }
    } catch (e) { debugPrint("Route error: $e"); }
  }

  void _processEsewaSDKPayment() {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(environment: Environment.test,
            clientId: PaymentConfig.clientId,
            secretId: PaymentConfig.secretKey),
        esewaPayment: EsewaPayment(
          productId: "ride_${DateTime.now().millisecondsSinceEpoch}",
          productName: selectedCar!.model,
          productPrice: fare.toStringAsFixed(0),
          callbackUrl: '',
        ),
        onPaymentSuccess: (data) => _confirmBooking(paymentStatus: "paid", method: "eSewa"),
        onPaymentFailure: (data) => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Payment Failed"))),
        onPaymentCancellation: (data) => debugPrint("Cancelled"),
      );
    } catch (e) { debugPrint("eSewa Error: $e"); }
  }


  Future<void> _confirmBooking({
    String paymentStatus = "unpaid",
    String method = "Cash",
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      /*await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'driverId': selectedCar!.driverId,
        'status': 'pending',
        'pickupAddress': _pickupAddress,
        'dropoffAddress': _dropoffAddress,
        'pickupLat': pickupLocation!.latitude,
        'pickupLng': pickupLocation!.longitude,
        'dropoffLat': dropOffLocation!.latitude,
        'dropoffLng': dropOffLocation!.longitude,
        'price': fare.toStringAsFixed(0),
        'carModel': selectedCar!.model,
        'paymentStatus': paymentStatus,
        'paymentMethod': method,
        'timestamp': FieldValue.serverTimestamp(),
        'otp': (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString(),
      });*/
      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'driverId': selectedCar!.driverId,
        'status': 'pending',
        'pickupAddress': _pickupAddress,
        'dropoffAddress': _dropoffAddress,
        'pickupLat': pickupLocation!.latitude,
        'pickupLng': pickupLocation!.longitude,
        'dropoffLat': dropOffLocation!.latitude,
        'dropoffLng': dropOffLocation!.longitude,
        'fare': fare,
        'carModel': selectedCar!.model,
        'paymentStatus': paymentStatus,
        'paymentMethod': method,
        'timestamp': FieldValue.serverTimestamp(),
        'otp': (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking Confirmed 🚖"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmContent(
            car: selectedCar!,
            userRole: UserRole.passenger,
            fare: fare,
            distance: distance,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  String generateEsewaUrl({
    required String amt,
    required String pid,
  }) {
    return "https://uat.esewa.com.np/epay/main?"
        "amt=$amt"
        "&pdc=0"
        "&psc=0"
        "&txAmt=0"
        "&tAmt=$amt"
        "&pid=$pid"
        "&scd=EPAYTEST"
        "&su=https://your-success-url.com"
        "&fu=https://your-failure-url.com";
  }


  Future<void> payWithEsewaWeb(double amount) async {
    final pid = DateTime.now().millisecondsSinceEpoch.toString();

    final url = Uri.parse(generateEsewaUrl(
      amt: amount.toStringAsFixed(0),
      pid: pid,
    ));

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch eSewa';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      extendBody: false,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildMap(),
          isWide ? _buildWebPanel() : _buildMobilePanel(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCenter,
        initialZoom: 14,
        onTap: (tapPos, point) => _updateLocationState(point, isSelectingPickup),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.prasannata.sajilo_ride',
        ),
        if (routePoints.isNotEmpty) PolylineLayer(
            polylines: [Polyline(points: routePoints, strokeWidth: 5, color: Colors.blueAccent)]),

        // Inside _buildMap()
        MarkerLayer(
          markers: [
            // 1. Current Pickup Marker
            if (pickupLocation != null)
              Marker(point: pickupLocation!, child: const Icon(Icons.my_location, color: Colors.green, size: 30)),

            // 2. Drop-off Marker
            if (dropOffLocation != null)
              Marker(point: dropOffLocation!, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),

            // 3. LIVE DRIVER MARKERS
            ...liveCars.map((driver) => Marker(
              point: LatLng(driver.latitude, driver.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => setState(() => selectedCar = driver),
                child: Image.asset(
                  driver.model.contains("Moto")
                      ? "assets/images/bike_icon.png"
                      : "assets/images/car_icon.png",
                  width: 35,
                ),
              ),
            )).toList(),
          ],
        ),
        /*MarkerLayer(markers: [
          if (pickupLocation != null) Marker(point: pickupLocation!,
              child: const Icon(Icons.my_location, color: Colors.green, size: 30)),
          if (dropOffLocation != null)
            Marker(point: dropOffLocation!, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
        ]),*/
      ],
    );
  }

  Widget _buildWebPanel() {
    return Positioned(
      right: 20, top: 20, bottom: 20,
      child: Container(width: 450, decoration: _panelDecoration(), child: _buildBookingContent()),
    );
  }

  Widget _buildMobilePanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: _panelDecoration(isMobile: true),
        child: _buildBookingContent(),
      ),
    );
  }

  BoxDecoration _panelDecoration({bool isMobile = false}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: isMobile ? const BorderRadius.vertical(top: Radius.circular(30)) : BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5)],
    );
  }

  Widget _buildBookingContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Where are you going?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _locationTile(Icons.circle, Colors.green, "Pickup", _pickupAddress, isSelectingPickup, () => setState(() => isSelectingPickup = true)),
          const SizedBox(height: 12),

          _locationTile(Icons.location_on, Colors.red, "Drop-off",
          _dropoffAddress, !isSelectingPickup, () => setState(() => isSelectingPickup = false)),

          /*TextFormField(
            onTap:  () => setState(() => isSelectingPickup = false),
            decoration: InputDecoration(
            suffixIcon: Icon(Icons.location_on,color: Colors.red,),
              labelText: "Drop-off",
              label:  Expanded(child: Text(_dropoffAddress, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),),
          ),
          ),*/
          const Divider(height: 40),
          Expanded(child: _buildRideSelector()),
          if (selectedCar != null) _buildFareFooter(),
        ],
      ),
    );
  }

  Widget _locationTile(IconData icon, Color color, String label, String address, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? Colors.orange.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? Colors.orange : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 15),
            Expanded(child: Text(address, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal),
            ),),
          ],
        ),
      ),
    );
  }

  /*Widget _buildRideSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (context, snapshot) {
        List<CarModel> liveCars = [];
        if (snapshot.hasData) {
          // Change this block in _buildRideSelector
          liveCars = snapshot.data!.docs.map((doc) {
            var d = doc.data() as Map<String, dynamic>;
            return CarModel(
              model: d['model'] ?? "Car",            // Changed from 'carModel'
              distance: 0,
              pricePerHour: (d['pricePerHour'] ?? 45).toDouble(),
              fuelCapacity: (d['fuelCapacity'] ?? 0).toDouble(),
              image: d['image'] ?? "",               // Changed from 'carImage'
              driverId: doc.id,
              carNumber: d['carNumber'] ?? 'N/A',
              driverName: d['driverName'] ?? 'Unknown Driver', // Changed from 'name'
              phone: d['phone'] ?? 'No Phone',
            );
          }).toList();
         /* liveCars = snapshot.data!.docs.map((doc) {
            var d = doc.data() as Map<String, dynamic>;
            return CarModel(
                     model: d['carModel'] ?? "Car",
                         distance: 0,
                     pricePerHour: (d['pricePerHour'] ?? 45).toDouble(),
                      fuelCapacity: (d['fuelCapacity'] ?? 0).toDouble(),
                        image: d['carImage'] ?? "",
                     driverId: doc.id,
                       carNumber: d['carNumber'] ?? 'N/A',
                   driverName: d['name'] ?? 'Unknown Driver',
                 phone: d['phone'] ?? 'No Phone',
            );
          }).toList();*/
        }
        final all = [...liveCars, ...carList];
        return ListView.separated(
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            bool isSel = selectedCar?.driverId == all[index].driverId;
            return ListTile(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarDriverDetailPage(car:
                    //all[index]
                      selectedCar!
                    ),
                  ),
                );
                 if (!context.mounted) return;
                //  Only when user confirms ride
                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Ride confirmed with ${all[index].driverName}"),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  setState(() {
                    selectedCar = all[index];
                    fare = distance > 0
                        ? distance * all[index].pricePerHour
                        : all[index].pricePerHour;
                  });
                }
              },

             /*leading: CircleAvatar(
                radius: 25,
                backgroundImage: all[index].image.startsWith('http')
                    ? NetworkImage(all[index].image)
                    : AssetImage(all[index].image) as ImageProvider,
              ),*/

              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[200],
                backgroundImage: all[index].image.isNotEmpty
                    ? (all[index].image.startsWith('http')
                    ? NetworkImage(all[index].image)
                    : AssetImage(all[index].image) as ImageProvider)
                    : const AssetImage('assets/images/car1.jpg'), // Add a default asset
              ),

              title: Text(
                all[index].model,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              subtitle: const Text("⚡ Close by • 4 Seats"),

              /*trailing: Text(
                "Rs ${(distance > 0
                    ? distance * all[index].pricePerHour
                    : all[index].pricePerHour).toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),*/
              trailing: Text(
                distance > 0
                    ? "Rs ${(distance * all[index].pricePerHour).toStringAsFixed(0)}"
                    : "Calculating...",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),

              selected: isSel,
              selectedTileColor: Colors.orange.withValues(alpha: 0.15),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSel ? Colors.orange : Colors.transparent,
                  width: 2,
                ),
              ),
            );
          },
        );
      },
    );
  }*/

  /*Widget _buildRideSelector() {
    String passengerHash = GeoHasher().encode(pickupLocation!.longitude, pickupLocation!.latitude);
    String searchPrefix = passengerHash.substring(0, 4);

    return StreamBuilder<QuerySnapshot>(
      // Querying 'users' collection for drivers to keep DB unified
      /*stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver').where('isOnline',isEqualTo: true).snapshots(),*/
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .where('isOnline', isEqualTo: true)
        // 3. Query drivers whose geohash starts with our prefix
            .where('location.geohash', isGreaterThanOrEqualTo: searchPrefix)
            .where('location.geohash', isLessThanOrEqualTo: '$searchPrefix\uf8ff')
            .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        /*if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No drivers nearby 📍"));
        }*/

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
         liveCars = snapshot.data!.docs.map((doc) {
            // Get the data map from the document
            final d = doc.data() as Map<String, dynamic>;
            // Pass the map and the document ID to your factory constructor
            return CarModel.fromMap(d, doc.id);
          }).toList();

        final all = [...liveCars, ...carList];

        return ListView.separated(
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final currentCar = all[index];
            bool isSel = selectedCar?.driverId == currentCar.driverId;

            return ListTile(
              onTap: () async {
                // FIX: Pass the tapped car, not the currently selected one!
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarDriverDetailPage(car: currentCar),
                  ),
                );

                if (result == true && context.mounted) {
                  setState(() {
                    selectedCar = currentCar;
                    // Fare logic: Distance * Rate
                    fare = distance > 0 ? (distance * currentCar.pricePerKm) : 0;
                  });
                }
              },
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[200],
                backgroundImage: currentCar.image.startsWith('http')
                    ? NetworkImage(currentCar.image)
                    : AssetImage('assets/images/car1.jpg') as ImageProvider,
              ),
              title: Row(
                children: [
                  Text(currentCar.model, style: const TextStyle(fontWeight: FontWeight.bold)),
                  _buildFuelBadge(currentCar.vehicleType),
                ],
              ),
              subtitle:  Text("⚡ ${currentCar.carNumber} • 4 Seats"),
              trailing: Text(
                distance > 0
                    ? "Rs ${(distance * currentCar.pricePerKm).toStringAsFixed(0)}"
                    : "Select Destination",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              selected: isSel,
              selectedTileColor: Colors.orange.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSel ? Colors.orange : Colors.transparent),
              ),
            );
          },
        );
      }
      }
    );
  }*/

  Widget _buildRideSelector() {
    // 1. Get the current Passenger's Geohash
    // Ensure pickupLocation is not null before this call
    if (pickupLocation == null) {
      return const Center(child: Text("Please select a pickup point"));
    }

    String passengerHash = GeoHasher().encode(pickupLocation!.longitude, pickupLocation!.latitude);

    // 2. Create a Search Prefix (4 characters = ~20km area, 5 characters = ~5km area)
    String searchPrefix = passengerHash.substring(0, 4);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .where('isOnline', isEqualTo: true)
      // String range query to find drivers in the same Geohash area
          .where('location.geohash', isGreaterThanOrEqualTo: searchPrefix)
          .where('location.geohash', isLessThanOrEqualTo: '$searchPrefix\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No drivers nearby 📍"));
        }

        // 3. Map Firestore documents to your CarModel
        List<CarModel> rawDrivers = snapshot.data!.docs.map((doc) {
          return CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // 4. REAL-WORLD ACCURACY: Filter by exact distance (e.g., 5.0 km)
        // This ensures we don't show drivers who are 15km away but in the same Geohash.
        List<CarModel> nearbyCars = rawDrivers.where((driver) {
          double distInMeters = Geolocator.distanceBetween(
            pickupLocation!.latitude,
            pickupLocation!.longitude,
            driver.latitude,
            driver.longitude,
          );
          return distInMeters <= 5000; // 5000 meters = 5km
        }).toList();

        if (nearbyCars.isEmpty) {
          return const Center(child: Text("Drivers are nearby, but too far for pickup."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: nearbyCars.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final currentCar = nearbyCars[index];
            bool isSel = selectedCar?.driverId == currentCar.driverId;

            return ListTile(
              onTap: () async {
                // Navigate to detail page
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarDriverDetailPage(car: currentCar),
                  ),
                );

                if (result == true && context.mounted) {
                  setState(() {
                    selectedCar = currentCar;
                    // Fare = Distance (km) * Price per Km
                    fare = distance > 0 ? (distance * currentCar.pricePerKm) : 0;
                  });
                }
              },
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                backgroundImage: (currentCar.image.isNotEmpty && currentCar.image.startsWith('http'))
                    ? NetworkImage(currentCar.image)
                    : const AssetImage('assets/images/default_car.png') as ImageProvider,
              ),
              title: Row(
                children: [
                  Text(currentCar.model, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildFuelBadge(currentCar.vehicleType),
                ],
              ),
              subtitle: Text("⚡ ${currentCar.carNumber} • 4 Seats"),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    distance > 0
                        ? "Rs ${(distance * currentCar.pricePerKm).toStringAsFixed(0)}"
                        : "Fare Info",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                  ),
                  if (distance > 0)
                    Text("${currentCar.pricePerKm}/km", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              selected: isSel,
              selectedTileColor: Colors.orange.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSel ? Colors.orange : Colors.transparent, width: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFuelBadge(String? type) {
    // Use 'Petrol' as a fallback if the type is null
    final fuelType = type?.toLowerCase() ?? 'petrol';
    bool isEV = fuelType == 'electric';

    // Define colors based on type
    Color badgeColor = isEV ? Colors.green : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 8), // Adds space between car name and badge
      decoration: BoxDecoration(
        // withValues is the modern, non-deprecated way to handle transparency
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        fuelType.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildFareFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),

        const Text("Payment Method",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            _paymentChip("Cash", Icons.payments_outlined),
            const SizedBox(width: 12),
            _paymentChip("eSewa", Icons.account_balance_wallet_outlined),
          ],
        ),

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            /*onPressed: (pickupLocation == null || dropOffLocation == null)
                ? null
                : () => selectedPayment == "eSewa"
                ? _processEsewaSDKPayment()
                : _confirmBooking(),*/
            onPressed: (pickupLocation == null || dropOffLocation == null)
                ? null
                : () {
              if (selectedPayment == "eSewa") {
                if (kIsWeb) {
                  payWithEsewaWeb(fare);
                } else {
                  _processEsewaSDKPayment();
                }
              } else {
                _confirmBooking();
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text(
                  "CONFIRM ${selectedCar!.model.toUpperCase()}",
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentChip(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPayment = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // When selected, it turns black like Uber
            color: isSelected ? Colors.orangeAccent: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.orangeAccent: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*Widget _buildRideSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (context, snapshot) {
        List<CarModel> liveCars = [];
        if (snapshot.hasData) {
          // Change this block in _buildRideSelector
          liveCars = snapshot.data!.docs.map((doc) {
            var d = doc.data() as Map<String, dynamic>;
            return CarModel(
              model: d['model'] ?? "Car",            // Changed from 'carModel'
              distance: 0,
              pricePerHour: (d['pricePerHour'] ?? 45).toDouble(),
              fuelCapacity: (d['fuelCapacity'] ?? 0).toDouble(),
              image: d['image'] ?? "",               // Changed from 'carImage'
              driverId: doc.id,
              carNumber: d['carNumber'] ?? 'N/A',
              driverName: d['driverName'] ?? 'Unknown Driver', // Changed from 'name'
              phone: d['phone'] ?? 'No Phone',
            );
          }).toList();
         /* liveCars = snapshot.data!.docs.map((doc) {
            var d = doc.data() as Map<String, dynamic>;
            return CarModel(
                     model: d['carModel'] ?? "Car",
                         distance: 0,
                     pricePerHour: (d['pricePerHour'] ?? 45).toDouble(),
                      fuelCapacity: (d['fuelCapacity'] ?? 0).toDouble(),
                        image: d['carImage'] ?? "",
                     driverId: doc.id,
                       carNumber: d['carNumber'] ?? 'N/A',
                   driverName: d['name'] ?? 'Unknown Driver',
                 phone: d['phone'] ?? 'No Phone',
            );
          }).toList();*/
        }
        final all = [...liveCars, ...carList];
        return ListView.separated(
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            bool isSel = selectedCar?.driverId == all[index].driverId;
            return ListTile(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarDriverDetailPage(car:
                    //all[index]
                      selectedCar!
                    ),
                  ),
                );
                 if (!context.mounted) return;
                //  Only when user confirms ride
                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Ride confirmed with ${all[index].driverName}"),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  setState(() {
                    selectedCar = all[index];
                    fare = distance > 0
                        ? distance * all[index].pricePerHour
                        : all[index].pricePerHour;
                  });
                }
              },

             /*leading: CircleAvatar(
                radius: 25,
                backgroundImage: all[index].image.startsWith('http')
                    ? NetworkImage(all[index].image)
                    : AssetImage(all[index].image) as ImageProvider,
              ),*/

              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[200],
                backgroundImage: all[index].image.isNotEmpty
                    ? (all[index].image.startsWith('http')
                    ? NetworkImage(all[index].image)
                    : AssetImage(all[index].image) as ImageProvider)
                    : const AssetImage('assets/images/car1.jpg'), // Add a default asset
              ),

              title: Text(
                all[index].model,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              subtitle: const Text("⚡ Close by • 4 Seats"),

              /*trailing: Text(
                "Rs ${(distance > 0
                    ? distance * all[index].pricePerHour
                    : all[index].pricePerHour).toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),*/
              trailing: Text(
                distance > 0
                    ? "Rs ${(distance * all[index].pricePerHour).toStringAsFixed(0)}"
                    : "Calculating...",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),

              selected: isSel,
              selectedTileColor: Colors.orange.withValues(alpha: 0.15),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSel ? Colors.orange : Colors.transparent,
                  width: 2,
                ),
              ),
            );
          },
        );
      },
    );
  }*/
