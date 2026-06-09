import 'dart:async';

import 'package:flutter/material.dart';

enum AdState { idle, watching, done }

class AdBanner extends StatefulWidget {
  final VoidCallback onReward;

  const AdBanner({super.key, required this.onReward});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  AdState _state = AdState.idle;
  int _secondsLeft = 30;
  Timer? _timer;
  bool _claimed = false;

  void _watch() {
    setState(() {
      _state = AdState.watching;
      _secondsLeft = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
          _state = AdState.done;
        }
      });
    });
  }

  void _claim() {
    if (_claimed) return;
    _claimed = true;
    widget.onReward();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Claimed 50 coins!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case AdState.idle:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ad_units, size: 32, color: Colors.orange),
            const SizedBox(height: 8),
            const Text('Watch ad to earn 50 coins',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Watch Ad'),
              onPressed: _watch,
            ),
          ],
        );

      case AdState.watching:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Ad playing... $_secondsLeft s',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 1 - (_secondsLeft / 30),
            ),
          ],
        );

      case AdState.done:
        return Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 40, color: Colors.green),
                  const SizedBox(height: 8),
                  const Text('+50 coins!',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  Text(_claimed ? 'Claimed!' : 'Tap to claim',
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  if (!_claimed) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _claim,
                      child: const Text('Claim 50 coins'),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _claim,
              ),
            ),
          ],
        );
    }
  }
}
