import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';

class CarManagementContent extends StatefulWidget {
  const CarManagementContent({super.key});

  @override
  State<CarManagementContent> createState() => _CarManagementContentState();
}

class _CarManagementContentState extends State<CarManagementContent> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  String _fuelType = 'Petrol';
  String? _carImageUrl; // Existing URL from Firestore
  File? _selectedImage; // Newly picked local file
  bool _isLoading = false;

  // --- LOGIC: PICK IMAGE FROM GALLERY ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Reduce size for faster free upload
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- LOGIC: UPLOAD TO CLOUDINARY (FREE STORAGE) ---
  Future<String?> _uploadToCloudinary(File imageFile) async {
    // Replace 'YOUR_CLOUD_NAME' with your actual Cloudinary name
    // Replace 'YOUR_UPLOAD_PRESET' with your unsigned preset name
    const String cloudName = "dvezp7njs";
    const String uploadPreset = "sajilo_preset";

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return jsonDecode(responseData)['secure_url'];
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Management"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            // Only update controllers if they are empty to prevent cursor jumping
            if (_modelController.text.isEmpty) _modelController.text = data['carModel'] ?? '';
            if (_plateController.text.isEmpty) _plateController.text = data['plateNumber'] ?? '';
            if (_colorController.text.isEmpty) _colorController.text = data['carColor'] ?? '';
            _fuelType = data['fuelType'] ?? 'Petrol';
            _carImageUrl = data['carImage']; // Load the URL
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- IMAGE SECTION ---
                  const Text("Car Photo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : (_carImageUrl != null
                            ? DecorationImage(image: NetworkImage(_carImageUrl!), fit: BoxFit.cover)
                            : null),
                      ),
                      child: (_selectedImage == null && _carImageUrl == null)
                          ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.orange),
                          Text("Upload Car Image", style: TextStyle(color: Colors.orange)),
                        ],
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(_modelController, "Car Model", "e.g. Toyota Corolla", Icons.car_rental),
                  _buildTextField(_plateController, "License Plate", "e.g. BA 1 PA 1234", Icons.numbers),
                  _buildTextField(_colorController, "Car Color", "e.g. White", Icons.color_lens),

                  const Text("Fuel Type", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _fuelType,
                    items: ['Petrol', 'Diesel', 'Electric', 'Hybrid'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() => _fuelType = newValue!);
                    },
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : () => _saveCarDetails(driverId!),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SAVE VEHICLE DETAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value!.isEmpty ? "Required field" : null,
      ),
    );
  }

  // --- LOGIC: UPLOAD IMAGE THEN SAVE DATA ---
  Future<void> _saveCarDetails(String driverId) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String? finalImageUrl = _carImageUrl;

        // 1. If a NEW image was picked, upload it to Cloudinary
        if (_selectedImage != null) {
          finalImageUrl = await _uploadToCloudinary(_selectedImage!);
        }

        // 2. Save all details (including image URL) to Firestore
        await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
          'carModel': _modelController.text,
          'plateNumber': _plateController.text,
          'carColor': _colorController.text,
          'fuelType': _fuelType,
          'carImage': finalImageUrl, // The URL is saved here
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vehicle details updated successfully!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}








/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';

class CarManagementContent extends StatefulWidget {
  const CarManagementContent({super.key});

  @override
  State<CarManagementContent> createState() => _CarManagementContentState();
}

class _CarManagementContentState extends State<CarManagementContent> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  String _fuelType = 'Petrol'; // Default value

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Management"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If data exists, pre-fill the controllers
          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            _modelController.text = data['carModel'] ?? '';
            _plateController.text = data['plateNumber'] ?? '';
            _colorController.text = data['carColor'] ?? '';
            _fuelType = data['fuelType'] ?? 'Petrol';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(Icons.directions_car_filled, size: 80, color: Colors.orange),
                  ),
                  const SizedBox(height: 20),
                  const Text("Vehicle Information", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("Update your car details so passengers can identify you.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

                  _buildTextField(_modelController, "Car Model", "e.g. Toyota Corolla", Icons.car_rental),
                  _buildTextField(_plateController, "License Plate", "e.g. BA 1 PA 1234", Icons.numbers),
                  _buildTextField(_colorController, "Car Color", "e.g. White", Icons.color_lens),

                  const SizedBox(height: 20),
                  const Text("Fuel Type", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _fuelType,
                    items: ['Petrol', 'Diesel', 'Electric', 'Hybrid'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() => _fuelType = newValue!);
                    },
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : () => _saveCarDetails(driverId!),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SAVE VEHICLE DETAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HELPER: TEXT FIELD UI ---
  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value!.isEmpty ? "Required field" : null,
      ),
    );
  }

  // --- LOGIC: SAVE TO FIRESTORE ---
  Future<void> _saveCarDetails(String driverId) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
          'carModel': _modelController.text,
          'plateNumber': _plateController.text,
          'carColor': _colorController.text,
          'fuelType': _fuelType,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Use merge to keep other profile data safe

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vehicle details updated successfully!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

 */