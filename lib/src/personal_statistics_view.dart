import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PersonalStatisticsView extends StatefulWidget {
  const PersonalStatisticsView({super.key});
  static const routeName = '/personal-statistics';

  @override
  State<PersonalStatisticsView> createState() => _PersonalStatisticsViewState();
}

class _PersonalStatisticsViewState extends State<PersonalStatisticsView> {
  bool showAllRoles = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("You must be signed in to view statistics.")),
      );
    }

    final statsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('statistics');

    return Scaffold(
      appBar: AppBar(title: const Text('Your Stats')),
      body: FutureBuilder<DocumentSnapshot>(
        future: statsRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("In Progress - Check back later!"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int goodWins = data['goodWins'] ?? 0;
          final int evilWins = data['evilWins'] ?? 0;
          final Map<String, dynamic> scriptCounts = data['scriptCounts'] ?? {};
          final Map<String, dynamic> roleCounts = data['roleCounts'] ?? {};

          final totalGames = goodWins + evilWins;
          final goodWinPercent =
              totalGames > 0 ? (goodWins / totalGames) * 100 : 0;
          final evilWinPercent =
              totalGames > 0 ? (evilWins / totalGames) * 100 : 0;
          Map<String, dynamic> roleWins =
              Map<String, dynamic>.from(data['roleWinCounts'] ?? {});
          Map<String, dynamic> roleTotals =
              Map<String, dynamic>.from(data['roleTotalCounts'] ?? {});

          final personalWins = data['personalWins'] ?? 0;
          final overallWinRate =
              totalGames > 0 ? personalWins / totalGames : 0.0;

          List<Map<String, dynamic>> roleStats =
              roleTotals.entries.map((entry) {
            final role = entry.key;
            final total = entry.value;
            final wins = roleWins[role] ?? 0;
            final winRate = total > 0 ? wins / total : 0.0;
            return {
              'role': role,
              'total': total,
              'wins': wins,
              'winRate': winRate,
            };
          }).toList();

          roleStats
              .sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

          final displayRoles =
              showAllRoles ? roleStats : roleStats.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Win Rate (Good vs Evil)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(sections: [
                      PieChartSectionData(
                        color: Colors.green,
                        value: goodWinPercent.toDouble(),
                        title: '${goodWinPercent.toStringAsFixed(1)}% Good',
                        radius: 60,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: evilWinPercent.toDouble(),
                        title: '${evilWinPercent.toStringAsFixed(1)}% Evil',
                        radius: 60,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Overall Win Rate',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${(overallWinRate * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                          '$goodWins Good wins, $evilWins Evil wins out of $totalGames games'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Most Played Scripts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...scriptCounts.entries.map(
                  (entry) => ListTile(
                    title: Text(entry.key),
                    trailing: Text(entry.value.toString()),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Most Played Roles',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    ...roleStats.take(5).map((role) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(role['role']),
                            subtitle: Text(
                              '${role['wins']} wins / ${role['total']} games • ${((role['winRate'] as double) * 100).toStringAsFixed(1)}% win rate',
                            ),
                          ),
                        )),
                    if (roleStats.length > 5)
                      ExpansionTile(
                        title: const Text('View All Roles'),
                        children: roleStats
                            .skip(5)
                            .map((role) => Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    title: Text(role['role']),
                                    subtitle: Text(
                                      '${role['wins']} wins / ${role['total']} games • ${((role['winRate'] as double) * 100).toStringAsFixed(1)}% win rate',
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
