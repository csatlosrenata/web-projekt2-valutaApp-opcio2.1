import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://api.frankfurter.app";

  // Konverzió adott összegre
  static Future<double?> convert(String from, String to, String amount) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/latest?from=$from&to=$to"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = data["rates"][to];
        final result = double.parse(amount) * rate;
        return double.parse(result.toStringAsFixed(2));
      }
    } catch (e) {
      print("Hiba: $e");
    }
    return null;
  }

  // Történeti adatok lekérése
  static Future<Map<String, double>> getHistory(String from, String to) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/2024-01-01..?from=$from&to=$to"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Map<String, dynamic> rates = data['rates'];
        return rates.map((key, value) => MapEntry(key, (value[to] as num).toDouble()));
      }
    } catch (e) {
      print("Hiba: $e");
    }
    return {};
  }

  // Aktuális napi árfolyam lekérése (getCurrentRate)
  static Future<double?> getCurrentRate(String from, String to) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/latest?from=$from&to=$to"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rates'][to] as num).toDouble();
        return rate;
      }
    } catch (e) {
      print("Hiba a getCurrentRate-nél: $e");
    }
    return null;
  }
}
