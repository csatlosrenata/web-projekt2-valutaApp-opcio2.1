import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  String from = "RON";
  String to = "EUR";
  double threshold = 5.0;
  String direction = "above";
  bool pushEnabled = true;

  Map<String, double> history = {};

  @override
  void initState() {
    super.initState();
    loadHistory();
    loadAlertsFromFirestore();
  }

  List<Map<String, dynamic>> firestoreAlerts = [];


  Future<void> saveAlertToFirestore() async {
  final pair = "$from/$to";
  await FirebaseFirestore.instance.collection('alerts').add({
    'pair': pair,
    'threshold': threshold,
    'direction': direction,
    'active': true,
    'timestamp': Timestamp.now(),
    'push': pushEnabled,
  });
}


  Future<void> loadHistory() async {
    final data = await ApiService.getHistory(from, to);
    setState(() {
      history = data;
      checkAlertCondition();
    });
  }

  Future<void> loadAlertsFromFirestore() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('alerts')
      .orderBy('timestamp', descending: true)
      .limit(20)
      .get();

  final List<Map<String, dynamic>> fetched = snapshot.docs.map((doc) => doc.data()).toList();

  setState(() {
    firestoreAlerts = fetched;
  });
}


  void checkAlertCondition() {
    final filtered = history.entries.where((entry) {
      final date = DateTime.tryParse(entry.key);
      return date != null && date.isAfter(DateTime(2024, 12, 31));
    }).toList();

    if (filtered.isEmpty) return;

    final currentRate = filtered.last.value;
    final conditionMet = direction == "above"
        ? currentRate > threshold
        : currentRate < threshold;

    if (conditionMet) {
      Future.delayed(const Duration(milliseconds: 500), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🔔 Riasztás: $from → $to árfolyam elérte a küszöböt! ($currentRate)"),
            backgroundColor: Colors.redAccent,
          ),
        );
      });
    }
  }

  String _shortMonth(int month) {
    const months = [
      "Jan", "Feb", "Már", "Ápr", "Máj", "Jún",
      "Júl", "Aug", "Szept", "Okt", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final pair = "$from$to";

    final filteredHistory = history.entries.where((entry) {
      final date = DateTime.tryParse(entry.key);
      return date != null && date.isAfter(DateTime(2024, 12, 31));
    }).toList();

    final values = filteredHistory.map((e) => e.value).toList();
    final labels = filteredHistory.map((e) => e.key).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Riasztás beállítása", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.amber),
            onPressed: () async {
              await saveAlertToFirestore();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Riasztás mentve Firestore-ba: $from → $to $direction $threshold"),
                  backgroundColor: Colors.green,
                ),
              );
            },


          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Valutapár", style: TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: from,
                        dropdownColor: Colors.black87,
                        style: const TextStyle(color: Colors.white),
                        items: ["RON", "EUR", "USD", "HUF", "GBP"]
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          from = v!;
                          loadHistory();
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text("→", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        value: to,
                        dropdownColor: Colors.black87,
                        style: const TextStyle(color: Colors.white),
                        items: ["RON", "EUR", "USD", "HUF", "GBP"]
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          to = v!;
                          loadHistory();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Küszöbérték", style: TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Pl. 5.00",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    threshold = double.tryParse(value) ?? threshold;
                  },
                ),
                const SizedBox(height: 20),
                const Text("Irány", style: TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: direction,
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white),
                  items: ["above", "below"]
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d == "above" ? "Fölötte" : "Alatta",
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => direction = v!),
                ),
                const SizedBox(height: 20),
                const Text("Push értesítés", style: TextStyle(fontSize: 16, color: Colors.white)),
                Switch(
                  value: pushEnabled,
                  activeColor: Colors.amber,
                  onChanged: (v) => setState(() => pushEnabled = v),
                ),
                const SizedBox(height: 30),
                const Text("Árfolyamdiagram", style: TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if (index >= 0 && index < labels.length) {
                                final date = DateTime.tryParse(labels[index]);
                                final label = date != null
                                    ? "${_shortMonth(date.month)} ${date.year}"
                                    : "";
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: Text(label,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10)),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 0.05,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(2),
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            values.length,
                            (i) => FlSpot(i.toDouble(), values[i]),
                          ),
                          isCurved: true,
                          color: Colors.amber,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Mentett riasztások", style: TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: firestoreAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = firestoreAlerts[index];
                    final timestamp = alert['timestamp'] as Timestamp?;
                    final formattedTime = timestamp != null
                        ? "${timestamp.toDate().day.toString().padLeft(2,'0')}/"
                          "${timestamp.toDate().month.toString().padLeft(2,'0')}/"
                          "${timestamp.toDate().year} "
                          "${timestamp.toDate().hour.toString().padLeft(2,'0')}:"
                          "${timestamp.toDate().minute.toString().padLeft(2,'0')}"
                        : "ismeretlen";

                    return Card(
                      color: Colors.black87,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${alert['pair']} (${alert['direction']})",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "${alert['threshold']}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    alert['active'] ? "Aktív" : "Inaktív",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: alert['active'] ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 10),
                                Chip(
                                  label: Text(
                                    alert['push'] ? "Push ON" : "Push OFF",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.blueGrey,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Mentve: $formattedTime",
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 50),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
