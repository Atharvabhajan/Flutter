import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../services/protect_mode_controller.dart';
import '../services/contact_service.dart';
import '../services/emergency_service.dart';
import '../services/practice_service.dart';
import '../services/stealth_mode_service.dart';
import 'settings_screen.dart';
import 'audio_recording_screen.dart';
import 'add_contact_screen.dart';
import 'contact_list_screen.dart';
import 'practice_mode_screen.dart';
import 'evidence_recorder_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const HomeScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EmergencyContact> _contacts      = [];
  bool                   _loadingContacts = false;
  bool                   _triggering      = false;
  late StreamSubscription _practiceSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoad();
    _practiceSubscription = PracticeService.practiceEventStream.listen((type) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Practice trigger detected [$type] — no real alert sent'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ));
    });
    ProtectModeController().isProtectModeActive.addListener(_onProtectModeChanged);
  }

  void _onProtectModeChanged() {
    if (!mounted) return;
    if (ProtectModeController().isProtectModeActive.value) {
      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
        content: const Text(
          'Listening for threat — analyzing audio silently…',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[700],
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ));
    } else {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    }
  }

  @override
  void dispose() {
    _practiceSubscription.cancel();
    ProtectModeController().isProtectModeActive.removeListener(_onProtectModeChanged);
    super.dispose();
  }

  void _checkPermissionsAndLoad() async {
    await PermissionService.requestEmergencyPermissions();
    _loadContacts();
  }

  void _loadContacts() async {
    setState(() => _loadingContacts = true);
    final result = await ContactService.getContacts();
    if (!mounted) return;
    if (result.success) {
      setState(() => _contacts = result.contacts);
    } else {
      _showError(result.message);
    }
    setState(() => _loadingContacts = false);
  }

  void _triggerEmergency() async {
    if (_triggering) return;
    setState(() => _triggering = true);

    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
      } catch (_) {
        try { pos = await Geolocator.getLastKnownPosition(); } catch (_) {}
      }

      final result = await EmergencyService.triggerEmergency(
        latitude:    pos?.latitude  ?? 0.0,
        longitude:   pos?.longitude ?? 0.0,
        triggerType: 'manual',
      );

      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Emergency alert sent to your contacts'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      } else {
        _showError(result.message);
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _triggering = false);
    }
  }

  void _logout() async {
    await AuthService.logout();
    widget.onLogout();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  void _showStealthDialog() {
    final phraseCtrl      = TextEditingController();
    final alertCtrl       = TextEditingController();
    final recStartCtrl    = TextEditingController();
    final recStopCtrl     = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 20,
          ),
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Enable Stealth Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('App will disguise as a Notes screen. '
                'Configure keywords to trigger actions silently.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
            const SizedBox(height: 22),

            // ── Section: Stealth Mode ─────────────────────────────────
            _DialogSection(label: 'STEALTH MODE', color: Colors.blueGrey),
            const SizedBox(height: 10),
            TextField(
              controller: phraseCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Unlock Phrase *',
                hintText: 'e.g. sunshine123',
                helperText: 'Type exactly this in Notes to exit stealth mode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Emergency Trigger ────────────────────────────
            _DialogSection(label: 'EMERGENCY TRIGGER', color: Colors.red),
            const SizedBox(height: 10),
            TextField(
              controller: alertCtrl,
              decoration: InputDecoration(
                labelText: 'Alert Keyword (Optional)',
                hintText: 'e.g. redrose',
                helperText: 'Typing + saving this word sends a silent emergency alert',
                helperStyle: TextStyle(color: Colors.red[400], fontSize: 11),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.crisis_alert_rounded, color: Colors.red),
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Audio Evidence ───────────────────────────────
            _DialogSection(label: 'AUDIO EVIDENCE', color: Colors.purple),
            const SizedBox(height: 10),
            TextField(
              controller: recStartCtrl,
              decoration: InputDecoration(
                labelText: 'Start Recording Keyword (Optional)',
                hintText: 'e.g. record',
                helperText: 'Typing + saving this word starts silent audio recording',
                helperStyle: TextStyle(color: Colors.purple[400], fontSize: 11),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.fiber_manual_record, color: Colors.purple),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: recStopCtrl,
              decoration: InputDecoration(
                labelText: 'Stop Recording Keyword (Optional)',
                hintText: 'e.g. stop',
                helperText: 'Typing + saving this word stops and saves the recording',
                helperStyle: TextStyle(color: Colors.purple[400], fontSize: 11),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.stop_circle_outlined, color: Colors.purple),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                final phrase = phraseCtrl.text.trim();
                if (phrase.isEmpty) return;
                StealthModeService.enableStealthMode(
                  phrase,
                  alertKeyword:       alertCtrl.text.trim(),
                  recordStartKeyword: recStartCtrl.text.trim(),
                  recordStopKeyword:  recStopCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Enable Stealth Mode'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isReal = PracticeService.isRealMode;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Silent Emergency Shield',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mode Status ─────────────────────────────────────────────
            _ModeBanner(
              isReal: isReal,
              onToggle: (val) async {
                await PracticeService.setRealMode(val);
                setState(() {});
              },
            ),
            const SizedBox(height: 20),

            // ── SOS Button ──────────────────────────────────────────────
            _SOSButton(
              isReal:     isReal,
              triggering: _triggering,
              onTap:      _triggerEmergency,
            ),
            const SizedBox(height: 28),

            // ── Features Grid ───────────────────────────────────────────
            _SectionLabel(label: 'Features'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _FeatureCard(
                  icon: Icons.mic_rounded,
                  color: Colors.blue,
                  title: 'Audio Analysis',
                  subtitle: 'Record & detect threats',
                  onTap: () => _navigate(AudioRecordingScreen(onRecordingComplete: _loadContacts)),
                ),
                _FeatureCard(
                  icon: Icons.folder_special_rounded,
                  color: Colors.deepPurple,
                  title: 'Evidence Recorder',
                  subtitle: 'Secure audio storage',
                  onTap: () => _navigate(const EvidenceRecorderScreen()),
                ),
                _FeatureCard(
                  icon: Icons.school_rounded,
                  color: Colors.teal,
                  title: 'Practice Guide',
                  subtitle: 'Learn volume trigger',
                  onTap: () => _navigate(const PracticeModeScreen()),
                ),
                _FeatureCard(
                  icon: Icons.settings_rounded,
                  color: Colors.orange,
                  title: 'Settings',
                  subtitle: 'Telegram & bot setup',
                  onTap: () => _navigate(const SettingsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Stealth Mode ─────────────────────────────────────────────
            _StealthCard(onTap: _showStealthDialog),
            const SizedBox(height: 28),

            // ── Emergency Contacts ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel(label: 'Emergency Contacts'),
                Row(children: [
                  if (_contacts.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const ContactListScreen()))
                          .then((_) => _loadContacts()),
                      child: const Text('View All'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _loadContacts,
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            _buildContactSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AddContactScreen(onContactAdded: _loadContacts),
        )),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Contact'),
      ),
    );
  }

  Widget _buildContactSection() {
    if (_loadingContacts) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }
    if (_contacts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(children: [
          Icon(Icons.group_add_outlined, size: 44, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text('No contacts yet', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 4),
          Text('Tap "Add Contact" to get started',
              style: TextStyle(color: Colors.grey[350], fontSize: 12)),
        ]),
      );
    }
    return Column(
      children: _contacts.map((c) => _ContactCard(contact: c)).toList(),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _ModeBanner extends StatelessWidget {
  final bool isReal;
  final ValueChanged<bool> onToggle;
  const _ModeBanner({required this.isReal, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isReal ? Colors.red.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReal ? Colors.red.shade200 : Colors.amber.shade300,
        ),
      ),
      child: Row(children: [
        Icon(
          isReal ? Icons.shield_rounded : Icons.science_rounded,
          color: isReal ? Colors.red[700] : Colors.amber[800],
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isReal ? 'Real Emergency Mode' : 'Practice Mode',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isReal ? Colors.red[800] : Colors.amber[900],
              ),
            ),
            Text(
              isReal ? 'Triggers send real alerts to contacts' : 'Triggers are simulated — safe to practice',
              style: TextStyle(
                fontSize: 11,
                color: isReal ? Colors.red[600] : Colors.amber[700],
              ),
            ),
          ],
        )),
        Switch(
          value: isReal,
          activeThumbColor: Colors.red,
          onChanged: onToggle,
        ),
      ]),
    );
  }
}

class _SOSButton extends StatelessWidget {
  final bool isReal;
  final bool triggering;
  final VoidCallback onTap;
  const _SOSButton({required this.isReal, required this.triggering, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isReal
              ? [Colors.red.shade600, Colors.red.shade800]
              : [Colors.grey.shade500, Colors.grey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isReal ? Colors.red : Colors.grey).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: triggering ? null : onTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: triggering
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          triggering ? 'Sending alert…' : 'Tap to trigger emergency',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          isReal ? 'Will alert all your contacts' : 'Practice mode — no real alert',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
        ),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _StealthCard extends StatelessWidget {
  final VoidCallback onTap;
  const _StealthCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade800,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 14),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stealth Mode',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text('Disguise app as a Notes screen',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          )),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
        ]),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final hasTelegram = contact.telegramChatId != null && contact.telegramChatId!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: Text(
            contact.name[0].toUpperCase(),
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text('${contact.relation} · ${contact.phone}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('P${contact.priority}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  )),
            ),
            const SizedBox(height: 4),
            if (hasTelegram)
              Row(children: [
                Icon(Icons.telegram, size: 14, color: Colors.blue[600]),
                const SizedBox(width: 2),
                Text('Telegram', style: TextStyle(fontSize: 10, color: Colors.blue[600])),
              ])
            else
              Text('No Telegram', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ],
        ),
      ]),
    );
  }
}

class _DialogSection extends StatelessWidget {
  final String label;
  final Color  color;
  const _DialogSection({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3, height: 14,
        color: color,
        margin: const EdgeInsets.only(right: 8),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    ]);
  }
}
