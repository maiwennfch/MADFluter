import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/db/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  List<Marker> markers = [];
  List<LatLng> routeCoordinates = [];


  @override
  void initState() {
    super.initState();
    loadMarkers();
    loadRouteCoordinates();
  }
  // Function to laod list of markers from database
  Future<void> loadMarkers() async {
    final dbMarkers = await DatabaseHelper.instance.getCoordinates();
    List<Marker> loadedMarkers = dbMarkers.map((record) {
      return Marker(
        point: LatLng(record['latitude'], record['longitude']),
        width: 80,
        height: 80,
        child: const Icon(
          Icons.location_pin,
          size: 60,
          color: Colors.red,
        ),
      );
    }).toList();
    setState(() {
      markers = loadedMarkers;
    });
  }

  void loadRouteCoordinates() {
    // Load list of coordinates in the route
    routeCoordinates = [
      const LatLng(40.38923590951672, -3.627749768768932),
      const LatLng(40.39050012345678, -3.62650087654321),
      const LatLng(40.39180023456789, -3.62520098765432),
      const LatLng(40.39310034567890, -3.62390109876543),
      const LatLng(40.39440045678901, -3.62260120987654),
      const LatLng(40.39570056789012, -3.62130132098765),
      const LatLng(40.39700067890123, -3.62000143209876),
      const LatLng(40.39830078901234, -3.61870154320987),
      const LatLng(40.39960089012345, -3.61740165432098),
      const LatLng(40.40090090123456, -3.61610176543210),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content(),
    );
  }

  Widget content(){
    return FlutterMap(
        options: const MapOptions(
              initialCenter: LatLng(40.38923590951672, -3.627749768768932),
            initialZoom: 15,
            interactionOptions: InteractionOptions(flags: InteractiveFlag.doubleTapZoom | InteractiveFlag.drag | InteractiveFlag.all)
        ),
        children: [
          openStreetMapTileLayer,
          MarkerLayer(markers: markers), // Marcadores cargados
          PolylineLayer(
              polylines: [
                Polyline(
                  points: routeCoordinates,
                  color: Colors.pink,
                  strokeWidth: 8.0,
                ),
              ])]
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
);