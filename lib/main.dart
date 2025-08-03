import 'dart:html' as html;
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
  bool _checkingRedirect = true;

  @override
  void initState() {
    super.initState();
    _checkRedirectToken();
  }

  void _checkRedirectToken() {
    final url = html.window.location.href;
    if (url.contains("access_token=")) {
      final fragment = Uri.parse(url).fragment;
      final params = Uri.splitQueryString(fragment);

      final accessToken = params['access_token'];
      final idToken = params['id_token'];

      String? userEmail;

      if (idToken != null) {
        final parts = idToken.split('.');
        final payload = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(payload));
        final claims = json.decode(decoded);
        userEmail = claims['emails']?[0] ?? claims['email'];
      }

      // Nettoyer l'URL après extraction
      html.window.history.replaceState(null, 'LED Controller', '/');

      // Naviguer vers la page LED avec email et token
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LedControlPage(
              accessToken: accessToken!,
              userEmail: userEmail ?? 'Utilisateur inconnu',
            ),
          ),
        );
      });
    } else {
      setState(() => _checkingRedirect = false);
    }
  }

  Future<void> _authenticateAndNavigate() async {
    final nonce = DateTime.now().millisecondsSinceEpoch.toString();
    final authUrl =
        'https://$tenantName.ciamlogin.com/$tenantName.onmicrosoft.com/oauth2/v2.0/authorize'
        '?client_id=$clientId'
        '&response_type=id_token token'
        '&redirect_uri=$redirectUri'
        '&scope=openid profile email'
        '&nonce=$nonce'
        '&prompt=login';

    try {
      await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: "https",
      );
      // ⚠️ Redirection se fait vers index.html → traitée dans initState()
    } catch (e) {
      print("❌ Auth échouée : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingRedirect) {
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
  final String userEmail;

  const LedControlPage({
    super.key,
    required this.accessToken,
    required this.userEmail,
  });

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
      appBar: AppBar(
        title: const Text('Contrôle LED'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text(
                userEmail,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          )
        ],
      ),
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
