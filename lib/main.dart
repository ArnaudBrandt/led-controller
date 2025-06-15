import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final functionUrl = const String.fromEnvironment('FUNCTION_URL');

void main() {
  print('🟡 FUNCTION_URL utilisée : $functionUrl');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LED Controller',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // TODO: Remplace cette URL plus tard par ton endpoint Azure


void main() {
  if (functionUrl.isEmpty) {
    throw Exception("FUNCTION_URL n'est pas défini. Utilise --dart-define.");
  }

  runApp(const MyApp());
}
    Future<void> sendColor(String color) async {
    final url = Uri.parse(functionUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'deviceId': 'esp32-led',
          'color': color,
        }),
      );
      print('✅ Response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = {
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'rainbow': Colors.purple,
      'off': Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Contrôle LED')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: colors.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: entry.value,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => sendColor(entry.key),
                child: Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}