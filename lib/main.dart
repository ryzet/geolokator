import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as latlong;

class CatatanModel {
  final latlong.LatLng position;
  final String note;
  final String address;
  final String kategori;

  CatatanModel({
    required this.position,
    required this.note,
    required this.address,
    required this.kategori,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<CatatanModel> _savedNotes = [];
  final MapController _mapController = MapController();

  // ===================== FIND CURRENT LOCATION =====================
  Future<void> _findMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position pos = await Geolocator.getCurrentPosition();

    _mapController.move(
      latlong.LatLng(pos.latitude, pos.longitude),
      15.0,
    );
  }

  // ===================== LONG PRESS HANDLER =====================
  void _handleLongPress(TapPosition tap, latlong.LatLng point) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(point.latitude, point.longitude);

    String address = placemarks.first.street ?? "Alamat tidak dikenal";

    // Pilih kategori
    String? kategori = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Kategori Marker"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Rumah"),
              onTap: () => Navigator.pop(context, "rumah"),
            ),
            ListTile(
              title: const Text("Toko"),
              onTap: () => Navigator.pop(context, "toko"),
            ),
            ListTile(
              title: const Text("Kantor"),
              onTap: () => Navigator.pop(context, "kantor"),
            ),
          ],
        ),
      ),
    );

    if (kategori == null) return;

    setState(() {
      _savedNotes.add(
        CatatanModel(
          position: point,
          note: "Catatan Baru",
          address: address,
          kategori: kategori,
        ),
      );
    });
  }

  // Icon berdasarkan kategori
  Icon _getIcon(String kategori) {
    switch (kategori) {
      case "rumah":
        return const Icon(Icons.home, color: Colors.blue, size: 40);
      case "toko":
        return const Icon(Icons.store, color: Colors.green, size: 40);
      case "kantor":
        return const Icon(Icons.business, color: Colors.orange, size: 40);
      default:
        return const Icon(Icons.location_on, color: Colors.red, size: 40);
    }
  }


  

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geo-Catatan")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: latlong.LatLng(-6.2, 106.8),
          initialZoom: 13,
          onLongPress: _handleLongPress,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(
            markers: _savedNotes
                .map(
                  (n) => Marker(
                    point: n.position,
                    child: _getIcon(n.kategori),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _findMyLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
