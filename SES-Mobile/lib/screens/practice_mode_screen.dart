import 'dart:async';
import 'package:flutter/material.dart';

class PracticeModeScreen extends StatefulWidget {
  const PracticeModeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen> {
  // 0 = idle, 1 = press1, 2 = press2, 3 = listening, 4 = done
  int    _demoStep      = 0;
  int    _listenSeconds = 0;
  Timer? _listenTimer;
  Timer? _resetTimer;

  @override
  void dispose() {
    _listenTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _simulatePress() {
    _resetTimer?.cancel();

    if (_demoStep >= 3) return;

    setState(() => _demoStep++);

    if (_demoStep == 3) {
      // Start 10-second listening countdown
      _listenSeconds = 0;
      _listenTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _listenSeconds++);
        if (_listenSeconds >= 10) {
          t.cancel();
          setState(() => _demoStep = 4);
        }
      });
    } else {
      // Auto-reset if next press not made within 2s (mirrors real behaviour)
      _resetTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _demoStep < 3) {
          setState(() => _demoStep = 0);
        }
      });
    }
  }

  void _resetDemo() {
    _listenTimer?.cancel();
    _resetTimer?.cancel();
    setState(() {
      _demoStep      = 0;
      _listenSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Practice Guide'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── How it works ─────────────────────────────────────────
            _sectionLabel('How It Works'),
            const SizedBox(height: 12),
            _HowItWorksCard(),
            const SizedBox(height: 24),

            // ── Interactive simulator ────────────────────────────────
            _sectionLabel('Interactive Demo'),
            const SizedBox(height: 4),
            Text(
              'Tap the button below to simulate pressing the volume button.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 14),
            _DemoSimulator(
              step:          _demoStep,
              listenSeconds: _listenSeconds,
              onPress:       _simulatePress,
              onReset:       _resetDemo,
            ),
            const SizedBox(height: 24),

            // ── What happens after 3 presses ─────────────────────────
            _sectionLabel('After 3 Presses'),
            const SizedBox(height: 12),
            _AfterPressesCard(),
            const SizedBox(height: 24),

            // ── Practice note ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This screen is always in Practice Mode. No real alerts are sent. '
                      'Switch to Real Mode on the home screen when you are ready.',
                      style: TextStyle(fontSize: 13, color: Colors.amber[900], height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );
}

// ── How It Works card ─────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _Step(
            n: 1,
            color: Colors.blue,
            icon: Icons.volume_down_rounded,
            title: 'First Press',
            desc: 'Press Volume Down once. Counter starts.',
            isLast: false,
          ),
          _Step(
            n: 2,
            color: Colors.orange,
            icon: Icons.volume_down_rounded,
            title: 'Second Press',
            desc: 'Press again within 2 seconds.',
            isLast: false,
          ),
          _Step(
            n: 3,
            color: Colors.red,
            icon: Icons.volume_down_rounded,
            title: 'Third Press',
            desc: 'Third press within 2 seconds starts listening.',
            isLast: false,
          ),
          _Step(
            n: 4,
            color: Colors.green,
            icon: Icons.hearing_rounded,
            title: 'Listening Phase',
            desc: 'App listens for 10 seconds. Threat words or shouting trigger the alert.',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final Color color;
  final IconData icon;
  final String title;
  final String desc;
  final bool isLast;

  const _Step({
    required this.n,
    required this.color,
    required this.icon,
    required this.title,
    required this.desc,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number + icon
              Column(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Step $n',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Text(title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                  ]),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      )),
                ],
              )),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 70, color: Colors.grey.shade100),
      ],
    );
  }
}

// ── Interactive Demo Simulator ────────────────────────────────────────────────

class _DemoSimulator extends StatelessWidget {
  final int step;
  final int listenSeconds;
  final VoidCallback onPress;
  final VoidCallback onReset;

  const _DemoSimulator({
    required this.step,
    required this.listenSeconds,
    required this.onPress,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Press indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PressIndicator(active: step >= 1, label: '1'),
              _PressConnector(active: step >= 2),
              _PressIndicator(active: step >= 2, label: '2'),
              _PressConnector(active: step >= 3),
              _PressIndicator(active: step >= 3, label: '3'),
            ],
          ),
          const SizedBox(height: 20),

          // Status text
          _StatusBox(step: step, listenSeconds: listenSeconds),
          const SizedBox(height: 20),

          // Buttons
          if (step == 0 || (step >= 1 && step < 3))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: step >= 3 ? null : onPress,
                icon: const Icon(Icons.volume_down_rounded),
                label: Text(
                  step == 0 ? 'Simulate Press 1' : 'Simulate Press ${step + 1}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (step == 3)
            SizedBox(
              width: double.infinity,
              child: LinearProgressIndicator(
                value: listenSeconds / 10,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Colors.red),
              ),
            ),
          if (step == 4)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (step > 0 && step < 4) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onReset,
              child: const Text('Reset', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ],
      ),
    );
  }
}

class _PressIndicator extends StatelessWidget {
  final bool active;
  final String label;
  const _PressIndicator({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.red : Colors.grey.shade200,
        boxShadow: active
            ? [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 8)]
            : [],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _PressConnector extends StatelessWidget {
  final bool active;
  const _PressConnector({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 3,
      color: active ? Colors.red : Colors.grey.shade200,
    );
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String text;
  const _StatusConfig(this.color, this.icon, this.text);
}

class _StatusBox extends StatelessWidget {
  final int step;
  final int listenSeconds;
  const _StatusBox({required this.step, required this.listenSeconds});

  @override
  Widget build(BuildContext context) {
    final configs = [
      const _StatusConfig(Colors.grey,   Icons.touch_app_rounded,   'Tap the button to simulate a volume press'),
      const _StatusConfig(Colors.blue,   Icons.looks_one_rounded,   'Press 1/3 — press again within 2 seconds'),
      const _StatusConfig(Colors.orange, Icons.looks_two_rounded,   'Press 2/3 — one more press to activate'),
            _StatusConfig(Colors.red,    Icons.hearing_rounded,     'Listening… ${10 - listenSeconds}s remaining\nSay "help", "danger" or shout'),
      const _StatusConfig(Colors.green,  Icons.check_circle_rounded,'Done — if a threat was detected, alert would be sent\n(No real alert in practice mode)'),
    ];
    final c = configs[step.clamp(0, 4)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(c.icon, color: c.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              c.text,
              style: TextStyle(
                color: c.color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── After Presses card ────────────────────────────────────────────────────────

class _AfterPressesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultRow(
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            label: 'Threat detected',
            desc: 'Emergency alert sent to all contacts via Telegram',
          ),
          const SizedBox(height: 12),
          _ResultRow(
            icon: Icons.cancel_rounded,
            color: Colors.grey,
            label: 'No threat detected',
            desc: 'Nothing happens — you stay safe, no alert sent',
          ),
          const SizedBox(height: 12),
          _ResultRow(
            icon: Icons.timer_rounded,
            color: Colors.blue,
            label: 'Timeout (10s)',
            desc: 'If no voice detected in 10 seconds, alert is cancelled',
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;
  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color,
            )),
            const SizedBox(height: 2),
            Text(desc, style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            )),
          ],
        )),
      ],
    );
  }
}
