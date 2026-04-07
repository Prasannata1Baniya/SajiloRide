class CarModel{
  final String model;
  final double distance;
  final double pricePerHour;
  final double fuelCapacity;
  final String image;
  final String driverId;
  final String carNumber;
  final String driverName;
  final String phone;

  CarModel({required this.model, required this.distance, required this.pricePerHour,
  required this.fuelCapacity,required this.image, required this.driverId,
    required this.carNumber, required this.driverName, required this.phone});

  factory CarModel.fromMap(Map<String, dynamic> map) => CarModel(
    model: map['model'] ?? '',
    distance: (map['distance'] ?? 0).toDouble(),
    pricePerHour: (map['pricePerHour'] ?? 0).toDouble(),
    fuelCapacity: (map['fuelCapacity'] ?? 0).toDouble(),
    image: map['image'] ?? '',
    driverId: map['driverId'] ?? '',
    carNumber: map['carNumber']?? '',
    driverName: map['driverName']?? '',
    phone: map['phone'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'model': model,
    'distance': distance,
    'pricePerHour': pricePerHour,
    'fuelCapacity': fuelCapacity,
    'image': image,
    'driverId': driverId,
    'carNumber': carNumber,
    'driverName':driverName,
    'phone': phone,
  };

}