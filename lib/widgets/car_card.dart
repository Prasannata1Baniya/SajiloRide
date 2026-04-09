/*import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajilo_ride/data/model/car_model.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  final LatLng pickupLocation;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? buttonColor;

  const CarCard({
    super.key,
    required this.car,
    required this.pickupLocation,
    this.onTap,
    this.isSelected = false,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orangeAccent : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.orangeAccent.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. CAR IMAGE
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: car.image.startsWith('http')
                    ? Image.network(car.image, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 50))
                    : Image.asset(car.image, fit: BoxFit.cover),
              ),
            ),

            // 2. CAR INFO
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.model,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniInfo(Icons.people, "4 seats"),
                      Text(
                        "Rs ${car.pricePerHour.toStringAsFixed(0)}/km",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),


            if (isSelected)
              Container(
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: const Center(
                  child: Text("SELECTED",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
*/




/*import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajilo_ride/data/model/car_model.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  final LatLng pickupLocation;
  final bool isSelected;
  final Color? buttonColor;


  const CarCard({
    super.key,
    required this.car,
    required this.pickupLocation,
    this.isSelected = false,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),

      child: Row(
        children: [
          // 🚗 CAR IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: car.image.startsWith('http')
                ? Image.network(
              car.image,
              width: 90,
              height: 70,
              fit: BoxFit.cover,
            )
                : Image.asset(
              car.image,
              width: 90,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          // 📄 DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🚘 NAME + RATING
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      car.model,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 16),
                        SizedBox(width: 2),
                        Text("4.8", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 📍 INFO ROW
                Row(
                  children: [
                    _info(Icons.place, "${car.distance.toStringAsFixed(1)} km"),
                    const SizedBox(width: 10),
                    _info(Icons.event_seat, "4 seats"),
                    const SizedBox(width: 10),
                    _info(Icons.local_gas_station, "Petrol"),
                  ],
                ),

                const SizedBox(height: 6),

                // 💰 PRICE
                Text(
                  "Rs ${car.pricePerHour.toStringAsFixed(0)} / km",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // ➡️ ARROW
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

}
*/




/*import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // Ensure you have this import
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/utils/text_styles.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  final LatLng pickupLocation;
  final Color? buttonColor;


  const CarCard({
    super.key,
    required this.car,
    required this.pickupLocation,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: () => _navigateToDetails(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: car.image.startsWith('http')
                  ? Image.network(car.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car, size: 50),
              )
                  : Image.asset(
                car.image,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.model,
                    style: AppTextStyles.bodyTextBlack,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    icon: Icons.gps_fixed,
                    label: 'Dist',
                    value: '${car.distance.toStringAsFixed(0)} km',
                  ),
                  _buildInfoRow(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Fuel',
                    value: '${car.fuelCapacity.toStringAsFixed(0)} L',
                  ),
                  _buildInfoRow(
                    icon: Icons.price_change_outlined,
                    label: 'Price',
                    value: 'Rs ${car.pricePerHour.toStringAsFixed(0)}/hr',
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 4.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor ?? Colors.orange,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                child: const Text(
                  "View Details",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

}
*/