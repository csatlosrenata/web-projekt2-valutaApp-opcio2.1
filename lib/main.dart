import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/rates_page.dart';
import 'pages/alerts_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ValutaApp());
}

class ValutaApp extends StatelessWidget {
  const ValutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valuta App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const HomePage(),
      routes: {
        '/rates': (context) => const RatesPage(),
        '/alerts': (context) => const AlertsPage(),
      },
    );
  }
}
