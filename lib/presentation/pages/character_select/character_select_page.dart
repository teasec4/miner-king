import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/player_profile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CharacterSelectPage extends StatelessWidget {
  const CharacterSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                'Choose Your Character',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Each character has unique bonuses.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const Spacer(),
              ...CharacterType.values.map((c) {
                final icon = switch (c) {
                  CharacterType.enthusiast => Icons.bolt,
                  CharacterType.engineer => Icons.build,
                  CharacterType.businessman => Icons.business,
                  CharacterType.speculator => Icons.show_chart,
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.deepPurple.shade50,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.read<GameState>().setCharacter(c);
                        context.go('/home');
                      },
                      child: Row(
                        children: [
                          Icon(icon, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  c.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.deepPurple.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
