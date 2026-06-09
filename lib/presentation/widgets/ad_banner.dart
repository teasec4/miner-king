import 'dart:async';

import 'package:flutter/material.dart';

class AdBanner extends StatefulWidget {
  final VoidCallback onReward;

  const AdBanner({super.key, required this.onReward});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  bool _onCooldown = false;
  int _cooldownLeft = 0;
  Timer? _cooldownTimer;

  void _startCooldown() {
    setState(() {
      _onCooldown = true;
      _cooldownLeft = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_cooldownLeft > 1) {
          _cooldownLeft--;
        } else {
          _cooldownTimer?.cancel();
          _onCooldown = false;
        }
      });
    });
  }

  void _showFullscreenAd() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AdOverlay(
          onReward: () {
            widget.onReward();
            _startCooldown();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_onCooldown) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: Colors.grey.shade100,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text('Next ad in ${_cooldownLeft}s',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: _showFullscreenAd,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.ad_units, size: 22, color: Colors.orange),
              const SizedBox(width: 10),
              const Text('Watch ad — earn 50 coins',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Watch'),
                onPressed: _showFullscreenAd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdOverlay extends StatefulWidget {
  final VoidCallback onReward;
  const _AdOverlay({required this.onReward});

  @override
  State<_AdOverlay> createState() => _AdOverlayState();
}

class _AdOverlayState extends State<_AdOverlay> {
  int _secondsLeft = 30;
  Timer? _timer;
  bool _done = false;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
          _done = true;
        }
      });
    });
  }

  void _claim() {
    if (_claimed) return;
    _claimed = true;
    widget.onReward();
    Navigator.of(context).pop();
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_done) ...[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text('$_secondsLeft s',
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 250,
                      child: LinearProgressIndicator(
                        value: 1 - (_secondsLeft / 30),
                        color: Colors.amber,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Ad is playing...',
                        style: TextStyle(fontSize: 16, color: Colors.white54)),
                  ] else ...[
                    const Icon(Icons.check_circle,
                        size: 80, color: Colors.greenAccent),
                    const SizedBox(height: 20),
                    const Text('+50 coins!',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent)),
                    const SizedBox(height: 16),
                    if (_claimed)
                      const Text('Claimed!',
                          style: TextStyle(fontSize: 18, color: Colors.white54))
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.monetization_on),
                        label: const Text('Claim 50 coins'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        onPressed: _claim,
                      ),
                  ],
                ],
              ),
            ),
            if (_done)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 28),
                  onPressed: _claim,
                ),
              ),
            if (_done)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _claim,
                    child: const Text('Return to game  →',
                        style: TextStyle(fontSize: 16, color: Colors.white38)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
