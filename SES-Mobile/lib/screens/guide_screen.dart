import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Guide'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ════════════════════════════════════════════
          // SECTION 1: WHAT THIS APP DOES
          // ════════════════════════════════════════════
          _GuideHeader(label: 'WHAT THIS APP DOES'),
          const SizedBox(height: 12),
          _GuideCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GuidePoint(
                  icon: Icons.sos_rounded,
                  title: 'Silent Emergency Alert',
                  desc: 'Send an alert to your trusted contacts instantly in case of emergency.',
                ),
                const SizedBox(height: 16),
                _GuidePoint(
                  icon: Icons.visibility_off_rounded,
                  title: 'Discreet Mode',
                  desc:
                      'Hide the app behind a fake notes interface so no one knows you\'re getting help.',
                ),
                const SizedBox(height: 16),
                _GuidePoint(
                  icon: Icons.mic_rounded,
                  title: 'Evidence Recording',
                  desc:
                      'Silently record audio as evidence in unsafe situations. No visible recording indicator.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ════════════════════════════════════════════
          // SECTION 2: REAL-LIFE USE CASES
          // ════════════════════════════════════════════
          _GuideHeader(label: 'REAL-LIFE USE CASES'),
          const SizedBox(height: 12),
          _GuideCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UseCase(
                  emoji: '🚨',
                  title: 'Unexpected Threat',
                  desc:
                      'Someone approaches you aggressively. Press volume button 3 times quickly to alert your family.',
                ),
                const SizedBox(height: 14),
                _Divider(),
                const SizedBox(height: 14),
                _UseCase(
                  emoji: '🤫',
                  title: 'Discreet Help',
                  desc:
                      'You\'re in an uncomfortable situation. Switch to Notes and type a keyword to silently request help.',
                ),
                const SizedBox(height: 14),
                _Divider(),
                const SizedBox(height: 14),
                _UseCase(
                  emoji: '📹',
                  title: 'Record Evidence',
                  desc:
                      'In a dispute or unsafe location. Use keywords to start recording without anyone noticing.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ════════════════════════════════════════════
          // SECTION 3: HOW TO SETUP
          // ════════════════════════════════════════════
          _GuideHeader(label: 'HOW TO SETUP'),
          const SizedBox(height: 12),
          _GuideCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SetupStep(
                  n: 1,
                  title: 'Connect Telegram',
                  desc: 'Go to Settings → Open the Telegram bot → Send /start → Verify your account.',
                ),
                const SizedBox(height: 16),
                _SetupStep(
                  n: 2,
                  title: 'Add Emergency Contacts',
                  desc:
                      'Add people you trust. They must send /start to the bot to share their Chat ID with you.',
                ),
                const SizedBox(height: 16),
                _SetupStep(
                  n: 3,
                  title: 'Configure Keywords (Optional)',
                  desc: 'Go to Settings → Enable Stealth Mode → Set keywords for alerts and recording.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ════════════════════════════════════════════
          // SECTION 4: HOW TO USE
          // ════════════════════════════════════════════
          _GuideHeader(label: 'HOW TO USE'),
          const SizedBox(height: 12),
          _GuideCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UsageMethod(
                  method: 'Volume Button Trigger',
                  steps: [
                    'Press Volume Down 3 times quickly',
                    'App listens for 10 seconds',
                    'Say a threat word like "help" or shout',
                    'Alert sent to all contacts',
                  ],
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                _Divider(),
                const SizedBox(height: 16),
                _UsageMethod(
                  method: 'Notes Keyword Trigger',
                  steps: [
                    'Enable Stealth Mode from home screen',
                    'Open Notes and type your alert keyword',
                    'Silent alert sent to contacts',
                    'Or type recording keywords to capture audio',
                  ],
                  color: Colors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Guide Header ──────────────────────────────────────────────────────────────

class _GuideHeader extends StatelessWidget {
  final String label;
  const _GuideHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 0.8,
          ),
        ),
      );
}

// ── Guide Card ────────────────────────────────────────────────────────────────

class _GuideCard extends StatelessWidget {
  final Widget child;
  const _GuideCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      );
}

// ── Guide Point ───────────────────────────────────────────────────────────────

class _GuidePoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _GuidePoint({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ── Use Case ──────────────────────────────────────────────────────────────────

class _UseCase extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  const _UseCase({required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ── Setup Step ────────────────────────────────────────────────────────────────

class _SetupStep extends StatelessWidget {
  final int n;
  final String title;
  final String desc;
  const _SetupStep({required this.n, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blue,
            child: Text(
              '$n',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ── Usage Method ──────────────────────────────────────────────────────────────

class _UsageMethod extends StatelessWidget {
  final String method;
  final List<String> steps;
  final Color color;
  const _UsageMethod({
    required this.method,
    required this.steps,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                method,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(
              steps.length,
              (idx) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          steps[idx],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        color: Colors.grey.shade100,
      );
}
