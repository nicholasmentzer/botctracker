import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> saveGameToFirestore({
  required String script,
  required List<String> roles,
  required String team,
  required String winningTeam,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not signed in');

  final firestore = FirebaseFirestore.instance;

  final gameData = {
    'script': script,
    'roles': roles,
    'team': team,
    'winningTeam': winningTeam,
    'timestamp': FieldValue.serverTimestamp(),
  };

  // Save game under the user's subcollection
  await firestore
      .collection('users')
      .doc(user.uid)
      .collection('games')
      .add(gameData);

  // Reference to the global stats document
  final statsRef = firestore.collection('stats').doc('global');
  final personalStatsRef = firestore
      .collection('users')
      .doc(user.uid)
      .collection('stats')
      .doc('statistics');

  await firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(statsRef);
    final data = snapshot.exists ? snapshot.data()! : {};

    // Get current nested maps (or start fresh)
    final currentScriptCounts =
        Map<String, dynamic>.from(data['scriptCounts'] ?? {});
    final currentRoleCounts =
        Map<String, dynamic>.from(data['roleCounts'] ?? {});

    // Update script count
    currentScriptCounts[script] = (currentScriptCounts[script] ?? 0) + 1;

    // Update each role count
    for (final role in roles) {
      currentRoleCounts[role] = (currentRoleCounts[role] ?? 0) + 1;
    }

    final personalSnapshot = await transaction.get(personalStatsRef);
    final personalData =
        personalSnapshot.exists ? personalSnapshot.data()! : {};

    final personalScriptCounts =
        Map<String, dynamic>.from(personalData['scriptCounts'] ?? {});
    final personalRoleCounts =
        Map<String, dynamic>.from(personalData['roleCounts'] ?? {});

    personalScriptCounts[script] = (personalScriptCounts[script] ?? 0) + 1;
    for (final role in roles) {
      personalRoleCounts[role] = (personalRoleCounts[role] ?? 0) + 1;
    }

    final personalRoleWinCounts =
        Map<String, dynamic>.from(personalData['roleWinCounts'] ?? {});
    final personalRoleTotalCounts =
        Map<String, dynamic>.from(personalData['roleTotalCounts'] ?? {});

    // Update win/loss counts per role
    for (final role in roles) {
      personalRoleTotalCounts[role] = (personalRoleTotalCounts[role] ?? 0) + 1;

      if (team == winningTeam) {
        personalRoleWinCounts[role] = (personalRoleWinCounts[role] ?? 0) + 1;
      }
    }

    transaction.set(
        statsRef,
        {
          'totalGames': (data['totalGames'] ?? 0) + 1,
          'goodWins': (data['goodWins'] ?? 0) + (winningTeam == 'Good' ? 1 : 0),
          'evilWins': (data['evilWins'] ?? 0) + (winningTeam == 'Evil' ? 1 : 0),
          'scriptCounts': currentScriptCounts,
          'roleCounts': currentRoleCounts,
        },
        SetOptions(merge: true));

    transaction.set(
        personalStatsRef,
        {
          'totalGames': (personalData['totalGames'] ?? 0) + 1,
          'personalWins': (personalData['personalWins'] ?? 0) +
              (team == winningTeam ? 1 : 0),
          'goodWins':
              (personalData['goodWins'] ?? 0) + (winningTeam == 'Good' ? 1 : 0),
          'evilWins':
              (personalData['evilWins'] ?? 0) + (winningTeam == 'Evil' ? 1 : 0),
          'scriptCounts': personalScriptCounts,
          'roleCounts': personalRoleCounts,
          'roleWinCounts': personalRoleWinCounts,
          'roleTotalCounts': personalRoleTotalCounts,
        },
        SetOptions(merge: true));
  });
}

class AddGameView extends StatefulWidget {
  static const routeName = '/add-game';

  const AddGameView({super.key});

  @override
  State<AddGameView> createState() => _AddGameViewState();
}

class _AddGameViewState extends State<AddGameView> {
  final _formKey = GlobalKey<FormState>();
  final _scriptController = TextEditingController();

  List<TextEditingController> _roleControllers = [TextEditingController()];
  String _team = 'Good';
  String _winningTeam = 'Good';

  String _selectedScript = 'Trouble Brewing';
  final TextEditingController _customScriptController = TextEditingController();

  final List<String> _presetScripts = [
    'Trouble Brewing',
    'Bad Moon Rising',
    'Sects & Violets',
    'Custom',
  ];

  void _addRoleField() {
    setState(() {
      _roleControllers.add(TextEditingController());
    });
  }

  void _removeRoleField(int index) {
    if (_roleControllers.length > 1) {
      setState(() {
        _roleControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _scriptController.dispose();
    _customScriptController.dispose();
    for (var controller in _roleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Game'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedScript,
                items: _presetScripts
                    .map((script) => DropdownMenuItem(
                          value: script,
                          child: Text(script),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedScript = val!),
                decoration: const InputDecoration(
                  labelText: 'Script',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_selectedScript == 'Custom') const SizedBox(height: 16),

              if (_selectedScript == 'Custom')
                TextFormField(
                  controller: _customScriptController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Script Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 20),

              // Dynamic role fields
              ..._roleControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Role ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_roleControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => _removeRoleField(index),
                        ),
                    ],
                  ),
                );
              }),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addRoleField,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Role'),
                ),
              ),
              const SizedBox(height: 20),

              // Team & Winning Team
              DropdownButtonFormField<String>(
                value: _team,
                items: ['Good', 'Evil']
                    .map(
                        (val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: (val) => setState(() => _team = val!),
                decoration: const InputDecoration(
                  labelText: 'Your Team',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _winningTeam,
                items: ['Good', 'Evil']
                    .map(
                        (val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: (val) => setState(() => _winningTeam = val!),
                decoration: const InputDecoration(
                  labelText: 'Winning Team',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final roles = _roleControllers
                        .map((controller) => controller.text.trim())
                        .where((role) => role.isNotEmpty)
                        .toList();

                    await saveGameToFirestore(
                      script: _selectedScript == 'Custom'
                          ? _customScriptController.text.trim()
                          : _selectedScript,
                      roles: roles,
                      team: _team,
                      winningTeam: _winningTeam,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Game saved!')),
                    );

                    _formKey.currentState!.reset();
                    _scriptController.clear();
                    _customScriptController.clear();
                    for (var controller in _roleControllers) {
                      controller.dispose();
                    }
                    setState(() {
                      _roleControllers = [TextEditingController()];
                      _team = 'Good';
                      _winningTeam = 'Good';
                    });
                  }
                },
                child: const Text('Save Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
