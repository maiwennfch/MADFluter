class WeatherData {
  late String placeName;
  late String weatherDescription;
  late double temperature;
  late double windSpeed;

  WeatherData({
    required this.placeName,
    required this.weatherDescription,
    required this.temperature,
    required this.windSpeed,
  });
}

WeatherData parseWeatherData(String weatherString) {
  List<String> lines = weatherString.split('\n');
  String placeName = '';
  String weatherDescription = '';
  double temperature = 0.0;
  double windSpeed = 0.0;

  for (String line in lines) {
    if (line.contains('Place Name:')) {
      int i = 0;
      while (i < line.length && line[i] != ':') {
        i++;
      }
      i++;
      while (i < line.length && line[i] != '[') {
        placeName += line[i];
        i++;
      }
    } else if (line.contains('Weather:')) {
      int i = 0;
      while (i < line.length && line[i] != ':') {
        i++;
      }
      i++;
      while (i < line.length && line[i] != ',') {
        weatherDescription += line[i];
        i++;
      }
    } else if (line.contains('Temp:')) {
      int i = 0;
      String tmpTemp = '';
      while (i < line.length && line[i] != ':') {
        i++;
      }
      i++;
      while (i < line.length && line[i] != 'C') {
        tmpTemp += line[i];
        i++;
      }
      temperature = double.parse(tmpTemp);
    } else if (line.contains('Wind:')) {
      int i = 0;
      String tmpWind = '';
      while(i < line.length && line[i] != 'e'){
        i++;
      }
      i = i + 3;
      while(i < line.length && line[i] != ','){
        tmpWind += line[i];
        i++;
      }
      windSpeed = double.parse(tmpWind);
    }
  }

  return WeatherData(
    placeName: placeName,
    weatherDescription: weatherDescription,
    temperature: temperature,
    windSpeed: windSpeed,
  );
}