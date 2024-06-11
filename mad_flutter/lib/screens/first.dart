import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/db/database_helper.dart';
import 'package:logger/logger.dart';



class FirstScreen extends StatefulWidget {
  @override
  DatabaseHelper db = DatabaseHelper.instance;

  FirstScreen({super.key});
  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  DatabaseHelper db = DatabaseHelper.instance;

  final logger = Logger();
  final _uidController = TextEditingController();
  final _tokenController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');
    String? token = prefs.getString('token');
    if (uid == null || token == null) {
      _showInputDialog();
    } else {
      logger.d("UID: $uid, Token: $token");
    }
  }
  Future<void> _showInputDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter UID and Token'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _uidController,
                  decoration: const InputDecoration(hintText: "UID"),
                ),
                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(hintText: "Token"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('uid', _uidController.text);
                await prefs.setString('token', _tokenController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _uidController.dispose();
    _tokenController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    //var logger = Logger();
    //logger.d("Debug message");
    //logger.w("Warning message!");
    //logger.e("Error message!!");
    return Scaffold(
    body:
    Center(
      child:
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('First Screen'),
          ElevatedButton(
            onPressed: () => _showAlertDialog(context),
            child: const Text('Click on it'),
          ),
          Switch(
            value: _positionStreamSubscription != null,
            onChanged: (value) {
              setState(() {
                if (value) {
                  startTracking();
                } else {
                  stopTracking();
                }
              });
            },
          ),
          if (_currentPosition != null)
            Text(
              'Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}',
            ),
        ],
      ),
    )
    );
  }
  void startTracking() async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Adjust the accuracy as needed
      distanceFilter: 10, // Distance in meters before an update is triggered
    );
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // insert into csv file
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            setState(() {
              _currentPosition = position;
            });
        writePositionToFile(position);
      },
    );

    // insert into sqflite db
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        db.insertCoordinate(position);
      },
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert Dialog'),
          content: const Text('If you want to have you location, click on it'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> writePositionToFile(Position position) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await file.writeAsString('$timestamp;${position.latitude};${position.longitude}\n', mode: FileMode.append);
  }

}


