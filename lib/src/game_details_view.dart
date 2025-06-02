import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GameDetailsView extends StatefulWidget {
  static const routeName = '/game-details';

  final String gameId;
  final String userId;

  const GameDetailsView({
    super.key,
    required this.gameId,
    required this.userId,
  });

  @override
  State<GameDetailsView> createState() => _GameDetailsViewState();
}

class _GameDetailsViewState extends State<GameDetailsView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _scriptController;
  late List<TextEditingController> _roleControllers;
  String _team = 'Good';
  String _winningTeam = 'Good';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scriptController = TextEditingController();
    _roleControllers = [];
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('games')
        .doc(widget.gameId)
        .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      _scriptController.text = data['script'] ?? '';
      _team = data['team'] ?? 'Good';
      _winningTeam = data['winningTeam'] ?? 'Good';

      final roles = List<String>.from(data['roles'] ?? []);
      _roleControllers =
          roles.map((r) => TextEditingController(text: r)).toList();
      if (_roleControllers.isEmpty)
        _roleControllers.add(TextEditingController());

      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    final updatedRoles = _roleControllers
        .map((c) => c.text.trim())
        .where((r) => r.isNotEmpty)
        .toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('games')
        .doc(widget.gameId)
        .update({
      'script': _scriptController.text.trim(),
      'roles': updatedRoles,
      'team': _team,
      'winningTeam': _winningTeam,
    });

    Navigator.pop(context); // go back after saving
  }

  Future<void> _deleteGame() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('games')
        .doc(widget.gameId)
        .delete();

    Navigator.pop(context); // go back after deleting
  }

  @override
  void dispose() {
    _scriptController.dispose();
    for (final c in _roleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGame,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _scriptController,
                decoration: const InputDecoration(labelText: 'Script'),
              ),
              const SizedBox(height: 16),
              ..._roleControllers.asMap().entries.map((entry) {
                final index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          decoration:
                              InputDecoration(labelText: 'Role ${index + 1}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_roleControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _roleControllers.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Role'),
                onPressed: () {
                  setState(() {
                    _roleControllers.add(TextEditingController());
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _team,
                items: ['Good', 'Evil']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _team = val!),
                decoration: const InputDecoration(labelText: 'Your Team'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _winningTeam,
                items: ['Good', 'Evil']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _winningTeam = val!),
                decoration: const InputDecoration(labelText: 'Winning Team'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
