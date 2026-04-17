import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/telegram_service.dart';
import '../services/stealth_mode_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Telegram state ────────────────────────────────────────────────────────────
  bool   _isConnected  = false;
  bool   _isVerifying  = false;
  String _statusText   = 'Not connected';

  // ── Stealth keywords state ────────────────────────────────────────────────────
  bool _editingKeywords = false;
  late TextEditingController _alertCtrl;
  late TextEditingController _recStartCtrl;
  late TextEditingController _recStopCtrl;
  String? _keywordError;

  @override
  void initState() {
    super.initState();
    _alertCtrl    = TextEditingController(text: StealthModeService.alertKeyword);
    _recStartCtrl = TextEditingController(text: StealthModeService.recordStartKeyword);
    _recStopCtrl  = TextEditingController(text: StealthModeService.recordStopKeyword);
  }

  @override
  void dispose() {
    _alertCtrl.dispose();
    _recStartCtrl.dispose();
    _recStopCtrl.dispose();
    super.dispose();
  }

  // ── Telegram ──────────────────────────────────────────────────────────────────
  Future<void> _openBot() async {
    final uri = Uri.parse('https://t.me/ABSES2711MYBot');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('Could not open Telegram', isError: true);
    }
  }

  Future<void> _verify() async {
    setState(() { _isVerifying = true; _statusText = 'Checking…'; });
    final chatId = await TelegramService.connectTelegram();
    if (chatId == null) {
      setState(() { _isVerifying = false; _statusText = 'Not connected'; });
      _showSnack('Chat ID not found. Open the bot and send /start first.', isError: true);
      return;
    }
    final saved = await TelegramService.saveChatId(chatId);
    if (saved) {
      setState(() {
        _isConnected = true;
        _isVerifying = false;
        _statusText  = 'Connected — Chat ID: $chatId';
      });
      _showSnack('Your Telegram is connected!');
    } else {
      setState(() { _isVerifying = false; _statusText = 'Not connected'; });
      _showSnack('Found Chat ID but failed to save.', isError: true);
    }
  }

  // ── Stealth keywords ──────────────────────────────────────────────────────────
  String? _validateKeywords() {
    final alert = _alertCtrl.text.trim().toLowerCase();
    final start = _recStartCtrl.text.trim().toLowerCase();
    final stop  = _recStopCtrl.text.trim().toLowerCase();

    final filled = [alert, start, stop].where((k) => k.isNotEmpty).toList();
    final unique = filled.toSet();
    if (unique.length < filled.length) {
      return 'Keywords must all be different from each other';
    }
    final phrase = StealthModeService.secretPhrase.toLowerCase();
    if (phrase.isNotEmpty && filled.contains(phrase)) {
      return 'Keywords cannot match the unlock phrase';
    }
    return null;
  }

  Future<void> _saveKeywords() async {
    final err = _validateKeywords();
    if (err != null) {
      setState(() => _keywordError = err);
      return;
    }
    setState(() => _keywordError = null);
    await StealthModeService.enableStealthMode(
      StealthModeService.secretPhrase,
      alertKeyword:       _alertCtrl.text.trim(),
      recordStartKeyword: _recStartCtrl.text.trim(),
      recordStopKeyword:  _recStopCtrl.text.trim(),
    );
    setState(() => _editingKeywords = false);
    _showSnack('Keywords saved');
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ════════════════════════════════════════════
          // SECTION: TELEGRAM
          // ════════════════════════════════════════════
          _SettingsHeader(label: 'TELEGRAM ALERTS'),
          const SizedBox(height: 8),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.telegram,
                      color: _isConnected ? Colors.green : Colors.blue, size: 26),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _isConnected ? 'Telegram Connected ✅' : 'Connect Your Telegram',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )),
                ]),
                const SizedBox(height: 8),
                Text(
                  _isConnected
                      ? _statusText
                      : 'Connect once so you receive emergency alerts on your own Telegram.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isConnected ? Colors.green[700] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                if (!_isConnected) ...[
                  const SizedBox(height: 14),
                  _NumberedStep(n: 1, text: 'Tap "Open Bot" below'),
                  _NumberedStep(n: 2, text: 'Send /start inside Telegram'),
                  _NumberedStep(n: 3, text: 'Come back here and tap "Verify"'),
                  const SizedBox(height: 14),
                  Row(children: [
                    ElevatedButton.icon(
                      onPressed: _openBot,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open Bot'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _isVerifying ? null : _verify,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isVerifying
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Verify'),
                    ),
                  ]),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // How contacts get chat ID
          _SettingsCard(
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How contacts get their Chat ID',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _NumberedStep(n: 1, text: 'They open Telegram → search @ABSES2711MYBot'),
                _NumberedStep(n: 2, text: 'They tap Start or send /start'),
                _NumberedStep(n: 3, text: 'Bot replies with their Chat ID instantly'),
                _NumberedStep(n: 4, text: 'They share that number with you'),
                _NumberedStep(n: 5, text: 'You enter it when adding them as a contact'),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _openBot,
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Open Bot'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ════════════════════════════════════════════
          // SECTION: STEALTH KEYWORDS
          // ════════════════════════════════════════════
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SettingsHeader(label: 'STEALTH KEYWORDS'),
              if (!_editingKeywords)
                TextButton.icon(
                  onPressed: StealthModeService.isStealthMode
                      ? () => setState(() => _editingKeywords = true)
                      : null,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (!StealthModeService.isStealthMode)
            _SettingsCard(
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Enable Stealth Mode first (from home screen) to configure keywords.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                )),
              ]),
            )
          else if (!_editingKeywords)
            _SettingsCard(
              child: Column(
                children: [
                  _KeywordRow(
                    icon: Icons.crisis_alert_rounded,
                    color: Colors.red,
                    label: 'Alert Keyword',
                    value: StealthModeService.alertKeyword,
                  ),
                  const Divider(height: 20),
                  _KeywordRow(
                    icon: Icons.fiber_manual_record,
                    color: Colors.purple,
                    label: 'Start Recording',
                    value: StealthModeService.recordStartKeyword,
                  ),
                  const Divider(height: 20),
                  _KeywordRow(
                    icon: Icons.stop_circle_outlined,
                    color: Colors.purple,
                    label: 'Stop Recording',
                    value: StealthModeService.recordStopKeyword,
                  ),
                ],
              ),
            )
          else
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency trigger
                  _KeywordField(
                    controller: _alertCtrl,
                    label: 'Alert Keyword',
                    hint: 'e.g. redrose',
                    helper: 'Triggers a silent emergency alert when saved in Notes',
                    icon: Icons.crisis_alert_rounded,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 14),

                  // Record start
                  _KeywordField(
                    controller: _recStartCtrl,
                    label: 'Start Recording Keyword',
                    hint: 'e.g. record',
                    helper: 'Starts silent audio recording when saved in Notes',
                    icon: Icons.fiber_manual_record,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 14),

                  // Record stop
                  _KeywordField(
                    controller: _recStopCtrl,
                    label: 'Stop Recording Keyword',
                    hint: 'e.g. stop',
                    helper: 'Stops and saves the recording when saved in Notes',
                    icon: Icons.stop_circle_outlined,
                    color: Colors.purple,
                  ),

                  if (_keywordError != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_keywordError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12))),
                    ]),
                  ],

                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveKeywords,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save Keywords'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _editingKeywords = false;
                        _keywordError    = null;
                        _alertCtrl.text    = StealthModeService.alertKeyword;
                        _recStartCtrl.text = StealthModeService.recordStartKeyword;
                        _recStopCtrl.text  = StealthModeService.recordStopKeyword;
                      }),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ]),
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  final String label;
  const _SettingsHeader({required this.label});

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

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _SettingsCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      );
}

class _NumberedStep extends StatelessWidget {
  final int n;
  final String text;
  const _NumberedStep({required this.n, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: Colors.blue,
            child: Text('$n',
                style: const TextStyle(fontSize: 10, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      );
}

class _KeywordRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;
  const _KeywordRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? 'Not set' : value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: value.isEmpty ? Colors.grey[400] : Colors.black87,
            ),
          ),
        ])),
      ]);
}

class _KeywordField extends StatelessWidget {
  final TextEditingController controller;
  final String   label;
  final String   hint;
  final String   helper;
  final IconData icon;
  final Color    color;
  const _KeywordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helper,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 2,
          helperStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, color: color, size: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );
}
