import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:meteo/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// Écran d'accueil
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma météo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenue sur l\'écran d\'accueil !',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Naviguer vers l'écran de progression lorsque le bouton est pressé
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgressScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
              child: Container(
                width: 400, // Modifier la larger de la jauge
                alignment: Alignment.center,
                child: const Text('Aller à l\'écran de progression'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Écran de progression
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  double progressValue = 0.0;
  int currentIndex = 0;
  bool isFetchingData = true;
  List<String> cities = ['Dakar', 'Paris', 'New york', 'Dubai', 'Bamako'];
  List<WeatherData> weatherDataList = [];
  Timer? timer;

  List<String> messages = [
    'Nous téléchargeons les données...',
    'C\'est presque fini...',
    'Plus que quelques secondes avant d\'avoir le résultat...'
  ];

  @override
  void initState() {
    super.initState();
    startProgress();
    startMessageRotation();
  }

  void startProgress() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        progressValue += 100 / 60; // Remplir à 100% en 60 secondes
      });

      if (progressValue >= 100) {
        timer.cancel();
        setState(() {
          isFetchingData = false;
        });
      }
    });
    fetchWeatherData();

  }

  void startMessageRotation() {

      timer = Timer.periodic(const Duration(seconds: 6), (timer) {
        setState(() {
          currentIndex = (currentIndex + 1) % messages.length;
        });
      });

  }

  Future<void> fetchWeatherData() async {
    String apiKey = '69630376f4aa415c16a67bd504d7b266';
    String lang = 'fr';
    for (int i = 0; i < cities.length; i++) {
      String city = cities[i];
      String apiUrl =
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&lang=$lang';

      try {
        var response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          var jsonData = jsonDecode(response.body);
          WeatherData weatherData = WeatherData.fromJson(jsonData);
          setState(() {
            weatherDataList.add(weatherData);
          });
        } else {
          if (kDebugMode) {
            print('Erreur lors de la requête API : ${response.statusCode}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erreur lors de la requête API : $e');
        }
      }
    }
  }

  void resetProgress() {
    setState(() {
      progressValue = 0.0; // Réinitialise laprogression à 0%
    });
    startProgress(); // Redémarre la progression
  }

  @override
  void dispose() {
    timer?.cancel(); // Arrête le timer lorsque l'écran est fermé
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progression'),
      ),
      body: SizedBox(
        height: 1000,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isFetchingData
                  ? CircularPercentIndicator(
                      radius: 80.0,
                      progressColor: Colors.blue.shade900,
                      lineWidth: 20.0,
                      center: Text(
                        "${progressValue.round()} %",
                        style: const TextStyle(fontSize: 20),
                      ),
                      percent: progressValue /
                          100, // Affiche la progression actuelle
                    )
                  : SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: Column(
                        children: [
                          Text(
                            'Données météo récupérées pour ${weatherDataList.length} villes:',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: weatherDataList.length,
                              itemBuilder: (context, index) {
                                WeatherData weatherData =
                                    weatherDataList[index];
                                return ListTile(
                                  leading: CachedNetworkImage(
                                    imageUrl:
                                        'https://openweathermap.org/img/w/${weatherData.icon}.png', // Affiche l'icône météo depuis une URL
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                  title: Text(weatherData.city),
                                  subtitle: Text("${weatherData.description}    ${weatherData.temperature}°C"),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 20),
              Text(
                ' ${messages[currentIndex]}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    resetProgress, // Réinitialise la progression lorsque le bouton est pressé
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modèle de données pour les données météo
class WeatherData {
  final String city;
  final String description;
  final String icon;
  final double temperature;

  WeatherData({
    required this.city,
    required this.description,
    required this.icon,
    required this.temperature,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city: json['name'],
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      temperature: json['main']['temp'],
    );
  }
}

// Écran de détails
class DetailsScreen extends StatelessWidget {
  final WeatherData weatherData;

  const DetailsScreen({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails'),
      ),
      body: Center(
        child: SizedBox(
          height: 5000,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weatherData.city,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              CachedNetworkImage(
                imageUrl:
                    'https://openweathermap.org/img/w/${weatherData.icon}.png',
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              const SizedBox(height: 16),
              Text(
                weatherData.description,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retourner à l'écran précédent (écran de progression)
                  Navigator.pop(context);
                },
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
