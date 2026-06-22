import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/player_profile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({super.key});
  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  CharacterType? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              const Text(
                'Choose Your Path',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Character list
              ...CharacterType.values.map((c) {
                final (icon, color, bg) = switch (c) {
                  CharacterType.miner => (
                    Icons.memory,
                    Colors.deepPurple,
                    Colors.deepPurple.shade50,
                  ),
                  CharacterType.engineer => (
                    Icons.build,
                    Colors.blue,
                    Colors.blue.shade50,
                  ),
                  CharacterType.businessman => (
                    Icons.attach_money,
                    Colors.amber.shade800,
                    Colors.amber.shade50,
                  ),
                  CharacterType.hustler => (
                    Icons.directions_run,
                    Colors.deepOrange,
                    Colors.deepOrange.shade50,
                  ),
                  CharacterType.student => (
                    Icons.school,
                    Colors.indigo,
                    Colors.indigo.shade50,
                  ),
                  CharacterType.debug => (
                    Icons.bug_report,
                    Colors.grey,
                    Colors.grey.shade200,
                  ),
                };
                final selected = _selected == c;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected ? bg : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selected = c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 24),
                            const SizedBox(width: 14),
                            Text(
                              c.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: selected ? color : Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            if (selected)
                              Icon(Icons.check_circle, color: color, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Description panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selected != null
                      ? Colors.white
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      _selected?.description ?? 'Select a character above',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _selected != null
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                      ),
                    ),
                    if (_selected != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton(
                          onPressed: () {
                            context.read<GameState>().setCharacter(_selected!);
                            context.go('/home');
                          },
                          child: const Text(
                            'Start',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
