import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/appbar_widget.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final amountController = TextEditingController(text: "1");
  String from = "USD";
  String to = "EUR";
  double? result;

  // Átváltás és mentés Firestore-ba
  Future<void> convert() async {
    final converted = await ApiService.convert(from, to, amountController.text);
    setState(() => result = converted);

    // Napi árfolyam mentése Firestore-ba
    final rate = await ApiService.getCurrentRate(from, to);
    if (rate != null) {
      final today = DateTime.now();
      final formattedDate =
          "${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}";

      final snapshot = await FirebaseFirestore.instance
          .collection('rates')
          .where('pair', isEqualTo: "$from-$to")
          .where('date', isEqualTo: formattedDate)
          .get();

      if (snapshot.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('rates').add({
          'pair': "$from-$to",
          'rate': rate,
          'date': formattedDate,
          'timestamp': Timestamp.now(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Valuta váltó"),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            width: 400,
            height: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Valuta váltó",
                    style: TextStyle(fontSize: 26, color: Colors.white)),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Összeg",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: from,
                      dropdownColor: Colors.black54,
                      style: const TextStyle(color: Colors.white),
                      items: ["USD", "EUR", "RON", "HUF", "GBP"]
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => from = v!),
                    ),
                    const Text(" → ", style: TextStyle(color: Colors.white)),
                    DropdownButton<String>(
                      value: to,
                      dropdownColor: Colors.black54,
                      style: const TextStyle(color: Colors.white),
                      items: ["USD", "EUR", "RON", "HUF", "GBP"]
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => to = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: convert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text("Átváltás"),
                ),
                const SizedBox(height: 20),
                if (result != null)
                  Text(
                    "$result $to",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
