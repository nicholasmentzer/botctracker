import 'package:flutter/material.dart';
import 'package:botctracker/src/settings/settings_view.dart';

class HomeView extends StatelessWidget {
  static const routeName = '/';

  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final tileStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BOTC Tracker'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Welcome to your Blood on the Clocktower tracker!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                children: [
                  _HomeTile(
                    icon: Icons.add_circle_outline,
                    label: 'Add Game',
                    onTap: () => Navigator.pushNamed(context, '/add-game'),
                    color: Colors.redAccent,
                  ),
                  _HomeTile(
                    icon: Icons.save_alt,
                    label: 'Saved Games',
                    onTap: () => Navigator.pushNamed(context, '/saved-games'),
                    color: Colors.deepPurpleAccent,
                  ),
                  _HomeTile(
                    icon: Icons.bar_chart,
                    label: 'Statistics',
                    onTap: () =>
                        Navigator.pushNamed(context, '/statistics-selection'),
                    color: Colors.teal,
                  ),
                  _HomeTile(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () =>
                        Navigator.pushNamed(context, SettingsView.routeName),
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _HomeTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
