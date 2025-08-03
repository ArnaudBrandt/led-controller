import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

final functionUrl = const String.fromEnvironment('FUNCTION_URL');
final clientId = const String.fromEnvironment('B2C_CLIENT_ID');
final tenantName = const String.fromEnvironment('B2C_TENANT_NAME');
final policy = const String.fromEnvironment('B2C_POLICY');
final redirectUri = const String.fromEnvironment('B2C_REDIRECT_URI');


// modif avec token corrigé


String? accessToken;

void main() {
  if (functionUrl.isEmpty) {
    throw Exception("FUNCTION_URL n'est pas défini.");
  }
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

  Future<void> authenticateWithMicrosoft() async {
    final authUrl =
        'https://$tenantName.b2clogin.com/$tenantName.onmicrosoft.com/oauth2/v2.0/authorize'
        '?p=$policy'
        '&client_id=$clientId'
        '&response_type=token'
        '&redirect_uri=$redirectUri'
        '&scope=openid';

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: "https",
    );

    accessToken = Uri.parse(result).fragment
        .split('&')
        .firstWhere((e) => e.startsWith('access_token='))
        .split('=')[1];

    print("🔐 Token récupéré : $accessToken");
  }

  Future<void> sendColor(String color) async {
    final url = Uri.parse(functionUrl);
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'deviceId': 'ESP32_Dev',
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
          children: [
            ElevatedButton(
              onPressed: authenticateWithMicrosoft,
              child: const Text("Connexion Microsoft"),
            ),
            const SizedBox(height: 20),
            ...colors.entries.map((entry) {
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
          ],
        ),
      ),
    );
  }
}
