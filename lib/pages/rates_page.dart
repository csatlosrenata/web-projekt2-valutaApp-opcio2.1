import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../widgets/appbar_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatesPage extends StatefulWidget {
  const RatesPage({super.key});

  @override
  State<RatesPage> createState() => _RatesPageState();
}

class _RatesPageState extends State<RatesPage> {
  String from = "EUR";
  String to = "RON";
  String selectedCurrency = "RON";

  Map<String, double> apiHistory = {};
  Map<String, double> firestoreHistory = {};

  Map<String, double> liveChanges = {
    "USD": 0.7898,
    "EUR": 0.1420,
    "GBP": 0.4396,
    "HUF": -0.0312,
  };

  Map<String, double> goldPrices = {
    "USD": 132.70,
    "EUR": 114.62,
    "HUF": 50800.00,
    "RON": 660.00,
  };

  String _shortMonth(int month) {
    const months = [
      "Jan", "Feb", "Már", "Ápr", "Máj", "Jún",
      "Júl", "Aug", "Szept", "Okt", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  @override
  void initState() {
    super.initState();
    loadApiHistory();
    loadRatesFromFirestore();
    liveChanges.forEach((currency, rate) {
      saveRateToFirestore(currency, rate);
    });
  }

  Future<void> loadApiHistory() async {
    final data = await ApiService.getHistory(from, to);
    setState(() => apiHistory = data);
  }

  void saveRateToFirestore(String pair, double rate) async {
    final today = DateTime.now();
    final formattedDate =
        "${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}";

    final snapshot = await FirebaseFirestore.instance
        .collection('rates')
        .where('pair', isEqualTo: pair)
        .where('date', isEqualTo: formattedDate)
        .get();

    if (snapshot.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('rates').add({
        'pair': pair,
        'rate': rate,
        'date': formattedDate,
        'timestamp': Timestamp.now(),
      });
    }
  }

  Future<void> loadRatesFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('rates')
        .where('pair', isEqualTo: "$from-$to")
        .get(); 

    final Map<String, double> fetchedRates = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateStr = data['date'] as String;
      final rate = (data['rate'] as num).toDouble();
      fetchedRates[dateStr] = rate;
    }

   
    final sortedRates = Map.fromEntries(
      fetchedRates.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)),
    );

    setState(() => firestoreHistory = sortedRates);
  }

  Widget buildLineChart(Map<String, double> history, String title) {
    final filteredHistory = history.entries
        .where((entry) => DateTime.tryParse(entry.key) != null)
        .toList();

    final values = filteredHistory.map((e) => e.value).toList();
    final labels = filteredHistory.map((e) => e.key).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 12),
          Expanded(
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
                      interval: 5,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.amber,
                    barWidth: 3,
                    spots: [
                      for (int i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFirestoreRatesTable() {
    final entries = firestoreHistory.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Napi Árfolyamok",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.black87),
              dataRowColor: MaterialStateProperty.all(Colors.black87),
              columns: const [
                DataColumn(label: Text('Dátum', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Árfolyam', style: TextStyle(color: Colors.white))),
              ],
              rows: List.generate(entries.length, (i) {
                final current = entries[i].value;
                final previous = i < entries.length - 1 ? entries[i + 1].value : current;

                Color cellColor;
                if (current > previous) {
                  cellColor = Colors.greenAccent;
                } else if (current < previous) {
                  cellColor = Colors.redAccent;
                } else {
                  cellColor = Colors.white;
                }

                return DataRow(
                  cells: [
                    DataCell(Text(entries[i].key, style: const TextStyle(color: Colors.white))),
                    DataCell(Text(current.toStringAsFixed(4), style: TextStyle(color: cellColor))),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLiveRatesSection(Map<String, double> changes) {
    final currencies = ["USD", "EUR", "GBP", "HUF"];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Élő árfolyam változások (24 óra)",
              style: TextStyle(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 12),
          ...currencies.map((currency) {
            final change = changes[currency] ?? 0.0;
            final isPositive = change >= 0;
            final changeColor = isPositive ? Colors.greenAccent : Colors.redAccent;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(currency,
                      style: const TextStyle(fontSize: 16, color: Colors.white)),
                  Text(
                    "${isPositive ? '+' : ''}${change.toStringAsFixed(4)}%",
                    style: TextStyle(fontSize: 16, color: changeColor),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        saveRateToFirestore(currency, changes[currency] ?? 0.0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text("$currency"),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildGoldPriceSelectorBox() {
    final price = goldPrices[selectedCurrency] ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Arany ár (1g)",
              style: TextStyle(fontSize: 18, color: Colors.amber)),
          Row(
            children: [
              Text(
                "$selectedCurrency: ${price.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedCurrency,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.black87,
                  iconEnabledColor: Colors.amber,
                  underline: const SizedBox(),
                  items: goldPrices.keys
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(color: Colors.amber)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedCurrency = v!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildCurrencySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: from,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.black87,
            iconEnabledColor: Colors.white,
            underline: const SizedBox(),
            items: ["USD", "EUR", "RON", "HUF", "GBP"]
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (v) {
              setState(() => from = v!);
              loadApiHistory();
              loadRatesFromFirestore();
            },
          ),
        ),
        const SizedBox(width: 10),
        const Text("→", style: TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: to,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.black87,
            iconEnabledColor: Colors.white,
            underline: const SizedBox(),
            items: ["USD", "EUR", "RON", "HUF", "GBP"]
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (v) {
              setState(() => to = v!);
              loadApiHistory();
              loadRatesFromFirestore();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Árfolyam diagram"),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              buildCurrencySelector(),
              const SizedBox(height: 20),
              buildLineChart(apiHistory, "Árfolyam diagram"),
              const SizedBox(height: 20),
              if (firestoreHistory.isNotEmpty) buildFirestoreRatesTable(),
              buildLiveRatesSection(liveChanges),
              buildGoldPriceSelectorBox(),
            ],
          ),
        ),
      ),
    );
  }
}
