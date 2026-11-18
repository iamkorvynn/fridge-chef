import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// First-run walkthrough: two ways to tell FridgeChef what's inside —
/// photograph the fridge (needs the user's own Gemini key) or tick
/// ingredients off a list (works fully offline).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.kitchen, size: 72, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'FridgeChef',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'What\'s in your fridge? We\'ll tell you what you can cook.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              const _WayCard(
                icon: Icons.camera_alt,
                title: '1. Photograph your fridge',
                body:
                    'Snap a photo and Gemini reads the ingredients for you. '
                    'Needs your own Gemini API key, added in Settings — '
                    'it stays on your phone and is never shared.',
              ),
              const SizedBox(height: 12),
              const _WayCard(
                icon: Icons.checklist,
                title: '2. Tick what you have',
                body:
                    'Pick from a checklist of common ingredients or type '
                    'your own. Works fully offline, no key needed.',
              ),
              const SizedBox(height: 12),
              const _WayCard(
                icon: Icons.restaurant_menu,
                title: '3. Cook what matches',
                body:
                    'Recipes are ranked by how many ingredients you already '
                    'have, with the missing ones listed. 34 real recipes, '
                    'bundled in the app.',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await SettingsService().setOnboardingDone();
                  onDone();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Start cooking', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WayCard extends StatelessWidget {
  const _WayCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
