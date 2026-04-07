import 'package:flutter/material.dart';

import '../../data/model/car_model.dart';

class CarDriverDetailPage extends StatelessWidget {
  final CarModel car;

  const CarDriverDetailPage({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: car.image.startsWith('http')
                    ? NetworkImage(car.image)
                    : (car.image.isNotEmpty
                    ? AssetImage(car.image)
                    : const AssetImage('assets/images/car1.jpg')) as ImageProvider,
              ),
            ),

            const SizedBox(height: 20),

            Text("Car Model: ${car.model}",
                style: const TextStyle(fontSize: 18)),

            Text("Car Number: ${car.carNumber}",
                style: const TextStyle(fontSize: 18)),

            const Divider(height: 30),

            Text("Driver: ${car.driverName}",
                style: const TextStyle(fontSize: 18)),

            Text("Phone: ${car.phone}",
                style: const TextStyle(fontSize: 18)),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true); // return selected
                },
                child: const Text("CONFIRM RIDE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
