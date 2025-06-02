import 'package:botctracker/src/game_details_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SavedGamesView extends StatefulWidget {
  static const routeName = '/saved-games';

  const SavedGamesView({super.key});

  @override
  State<SavedGamesView> createState() => _SavedGamesViewState();
}

class _SavedGamesViewState extends State<SavedGamesView> {
  String? selectedScript;
  String? selectedRole;
  DateTimeRange? selectedDateRange;

  void _showFilterDialog(BuildContext context) {
    String? tempScript = selectedScript;
    String? tempRole = selectedRole;
    DateTimeRange? tempDateRange = selectedDateRange;

    final scriptController = TextEditingController(text: tempScript ?? '');
    final roleController = TextEditingController(text: tempRole ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Games'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Script Name'),
                  controller: scriptController,
                  onChanged: (value) {
                    tempScript = value.isEmpty ? null : value;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Role'),
                  controller: roleController,
                  onChanged: (value) {
                    tempRole = value.isEmpty ? null : value;
                  },
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    tempDateRange != null
                        ? '${tempDateRange!.start.toLocal().toString().split(' ').first} - ${tempDateRange!.end.toLocal().toString().split(' ').first}'
                        : 'Select Date Range',
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      tempDateRange = picked;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedScript = tempScript;
                  selectedRole = tempRole;
                  selectedDateRange = tempDateRange;
                });
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You must be signed in to view games.')),
      );
    }

    final gamesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: gamesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No games saved yet.'));
          }

          final docs = snapshot.data!.docs;

          final filteredGames = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final scriptMatch =
                selectedScript == null || data['script'] == selectedScript;
            final roleMatch = selectedRole == null ||
                (data['roles'] as List).contains(selectedRole);
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final dateMatch = selectedDateRange == null ||
                (timestamp != null &&
                    timestamp.isAfter(selectedDateRange!.start) &&
                    timestamp.isBefore(selectedDateRange!.end));

            return scriptMatch && roleMatch && dateMatch;
          }).toList();

          if (filteredGames.isEmpty) {
            return const Center(
                child: Text('No games match the selected filters.'));
          }

          return ListView.builder(
            itemCount: filteredGames.length,
            itemBuilder: (context, index) {
              final game = filteredGames[index].data() as Map<String, dynamic>;

              final roles = (game['roles'] as List).join(', ');
              final script = game['script'] ?? 'Unknown Script';
              final team = game['team'] ?? 'Unknown';
              final winningTeam = game['winningTeam'] ?? 'Unknown';
              final timestamp = (game['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      GameDetailsView.routeName,
                      arguments: {
                        'gameId': filteredGames[index].id,
                        'userId': user.uid,
                      },
                    );
                  },
                  title: Text(script,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      Text('Roles: $roles\nTeam: $team | Winner: $winningTeam'),
                  trailing: timestamp != null
                      ? Text(
                          '${timestamp.month}/${timestamp.day}/${timestamp.year}',
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
