import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

final functionUrl = const String.fromEnvironment('FUNCTION_URL');
final clientId = const String.fromEnvironment('B2C_CLIENT_ID');
final tenantName = const String.fromEnvironment('B2C_TENANT_NAME');
final redirectUri = const String.fromEnvironment('B2C_REDIRECT_URI');

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
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    // Ici tu peux ajouter un "silent login" si CIAM le supporte via iframe, sinon on reste ici
    setState(() => _checkingSession = false);
  }

  Future<void> _authenticateAndNavigate() async {
    final authUrl =
        'https://$tenantName.ciamlogin.com/$tenantName/oauth2/v2.0/authorize'
        '?client_id=$clientId'
        '&response_type=token'
        '&redirect_uri=$redirectUri'
        '&scope=openid'
        '&prompt=login';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: "https",
      );

      final token = Uri.parse(result).fragment
          .split('&')
          .firstWhere((e) => e.startsWith('access_token='))
          .split('=')[1];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LedControlPage(accessToken: token),
        ),
      );
    } catch (e) {
      print("❌ Auth échouée : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('LED Controller')),
      body: Center(
        child: ElevatedButton(
          onPressed: _authenticateAndNavigate,
          child: const Text("Connexion Microsoft"),
        ),
      ),
    );
  }
}

class LedControlPage extends StatelessWidget {
  final String accessToken;
  const LedControlPage({super.key, required this.accessToken});

  Future<void> sendColor(String color) async {
    final url = Uri.parse(functionUrl);
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
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
