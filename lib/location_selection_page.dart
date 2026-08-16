 import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSelectionPage extends StatefulWidget {
  final String? initialLocation;
  const LocationSelectionPage({super.key, this.initialLocation});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  String? selectedLocation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
  }

  // Logic ya kupata Current Location (Bure)
  Future<void> _getCurrentLocation() async {
    setState(() => isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );

        // Geocoding: Badilisha coordinates kuwa Jina la Mahali
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            // Mfano: "Kinondoni, Dar es Salaam"
            selectedLocation = "${place.locality}, ${place.administrativeArea}";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context, widget.initialLocation),
        ),
        title: Text(
          'Add Location',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Current Location Trigger
          ListTile(
            onTap: _getCurrentLocation,
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.my_location, color: Colors.white, size: 20),
            ),
            title: Text(
              "Use Current Location",
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("Tap to detect your location", style: TextStyle(color: Colors.grey)),
            trailing: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : null,
          ),

          const Divider(height: 1),

          // 2. Selection Preview (Ikitokea)
          if (selectedLocation != null)
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: Text(selectedLocation!, style: TextStyle(color: textColor)),
              trailing: Container(
                height: 24,
                width: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
            ),

          const Spacer(),

          // 3. Bottom Button (Match TagUsersPage style)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedLocation != null 
                    ? () => Navigator.pop(context, selectedLocation) 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
