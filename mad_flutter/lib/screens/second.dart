import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '/db/database_helper.dart';
import 'package:weather/weather.dart';
import 'weather_data.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  List<List<String>> _coordinates = [];
  List<List<String>> _dbCoordinates = []; // For coordinates from the database

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
    _loadDbCoordinates();
  }

  Future<void> _loadCoordinates() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    List<String> lines = await file.readAsLines();
    setState(() {
      _coordinates = lines.map((line) => line.split(';')).toList();
    });
  }

  Future<void> _loadDbCoordinates() async {
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates(); // Corrected
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(), // Corrected
        c['latitude'].toString(), // Corrected
        c['longitude'].toString() // Corrected
      ]).toList();
    });
  }

  Future<String> _getWeatherDisplay(String latitude, String longitude) async {
    double lat = double.parse(latitude);
    double lon = double.parse(longitude);
    WeatherFactory wf = WeatherFactory("6102611944796ee7eb4043832e0b17da");
    Weather w = await wf.currentWeatherByLocation(lat, lon);
    WeatherData finalData = parseWeatherData(w.toString());

    String emojiWeather = '';
    if (finalData.weatherDescription.contains('Clear')) {
      emojiWeather = "☀️";
    } else if (finalData.weatherDescription.contains('Snow')) {
      emojiWeather = '❄️';
    } else if (finalData.weatherDescription.contains('Rain')) {
      emojiWeather = "🌧️";
    } else if (finalData.weatherDescription.contains('Clouds')) {
      emojiWeather = "☁️";
    } else if (finalData.weatherDescription.contains('Thunderstorm')) {
      emojiWeather = "⚡";
    } else if (finalData.weatherDescription.contains('Haze')) {
      emojiWeather = "🌫️";
    } else {
      emojiWeather = "❓";
    }

    return """
      $emojiWeather: ${finalData.weatherDescription}
      temp: ${finalData.temperature} °C
      windSpeed: ${finalData.windSpeed} km/h
    """;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Screen'),
      ),
      body: ListView.builder(
        itemCount: _coordinates.length + _dbCoordinates.length, // Combined count
        itemBuilder: (context, index) {
          if (index < _coordinates.length) {
            var coord = _coordinates[index];
            return ListTile(
              title: Text('CSV Timestamp: ${coord[0]}'),
              subtitle: Text('Latitude: ${coord[1]}, Longitude: ${coord[2]}'),
            );
          } else {
            var dbIndex = index - _coordinates.length;
            var coord = _dbCoordinates[dbIndex];
            return FutureBuilder<String>(
              future: _getWeatherDisplay(coord[1], coord[2]), // Fetch weather data asynchronously
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text('DB Timestamp: ${coord[0]}', style: const TextStyle(color: Colors.blue)),
                    subtitle: Text('Loading weather...', style: const TextStyle(color: Colors.blue)),
                  );
                } else if (snapshot.hasError) {
                  return ListTile(
                    title: Text('DB Timestamp: ${coord[0]}', style: const TextStyle(color: Colors.blue)),
                    subtitle: Text('Error loading weather', style: const TextStyle(color: Colors.blue)),
                  );
                } else {
                  return ListTile(
                    title: Text('DB Timestamp: ${coord[0]}', style: const TextStyle(color: Colors.blue)),
                    subtitle: Text(snapshot.data ?? 'No weather data', style: const TextStyle(color: Colors.blue)),
                    onTap: () {
                      _showDeleteDialog(coord[0], snapshot.data ?? ''); // Show delete confirmation dialog with weather data
                    },
                    onLongPress: () => _showUpdateDialog(coord[0], coord[1], coord[2]),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  void _showUpdateDialog(String timestamp, String currentLat, String currentLong) {
    TextEditingController latController = TextEditingController(text: currentLat);
    TextEditingController longController = TextEditingController(text: currentLong);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update coordinates for $timestamp"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: latController,
                decoration: const InputDecoration(labelText: "Latitude"),
              ),
              TextField(
                controller: longController,
                decoration: const InputDecoration(labelText: "Longitude"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Update"),
              onPressed: () async {
                Navigator.of(context).pop();
                await DatabaseHelper.instance.updateCoordinate(timestamp, latController.text, longController.text);
                _loadDbCoordinatesAndUpdate();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String timestamp, String valToDisplay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm delete $timestamp"),
          content: Text("${valToDisplay}\nDo you want to delete this coordinate?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () async {
                await DatabaseHelper.instance.deleteCoordinate(timestamp);
                Navigator.of(context).pop(); // Dismiss the dialog
                _loadDbCoordinatesAndUpdate(); // Reload data and update UI
              },
            ),
          ],
        );
      },
    );
  }

  void _loadDbCoordinatesAndUpdate() async {
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates();
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(),
        c['latitude'].toString(),
        c['longitude'].toString()
      ]).toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("didChangeDependencies: Dependencies updated.");
  }

  @override
  void didUpdateWidget(SecondScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget: The widget has been updated from the parent.");
  }

  @override
  void dispose() {
    print("dispose: Cleaning up before the state is destroyed.");
    super.dispose();
  }
}
