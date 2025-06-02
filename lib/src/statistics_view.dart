import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsView extends StatefulWidget {
  static const routeName = '/statistics';

  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  bool loading = true;
  int goodWins = 0;
  int evilWins = 0;
  Map<String, int> scriptCounts = {};
  Map<String, int> roleCounts = {};

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('stats')
          .doc('global')
          .get();

      final data = doc.data();

      if (data != null) {
        setState(() {
          goodWins = data['goodWins'] ?? 0;
          evilWins = data['evilWins'] ?? 0;
          scriptCounts = Map<String, int>.from(data['scriptCounts'] ?? {});
          roleCounts = Map<String, int>.from(data['roleCounts'] ?? {});
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Global Statistics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Win Rate (Good vs Evil)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: goodWins.toDouble(),
                      title:
                          'Good ${goodWins + evilWins > 0 ? (goodWins / (goodWins + evilWins) * 100).toStringAsFixed(1) : '0'}%',
                      color: Colors.green,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: evilWins.toDouble(),
                      title:
                          'Evil ${goodWins + evilWins > 0 ? (evilWins / (goodWins + evilWins) * 100).toStringAsFixed(1) : '0'}%',
                      color: Colors.red,
                      radius: 60,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Most Popular Scripts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final entry in (scriptCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .take(5))
              ListTile(
                title: Text(entry.key),
                trailing: Text('${entry.value} plays'),
              ),
            const SizedBox(height: 24),
            const Text('Most Played Roles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final entry
                in (roleCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                  ..take(5))
              ListTile(
                title: Text(entry.key),
                trailing: Text('${entry.value} times'),
              ),
          ],
        ),
      ),
    );
  }
}
