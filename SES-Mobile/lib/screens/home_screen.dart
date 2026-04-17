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
    final theme  = Theme.of(context);
    final isReal = PracticeService.isRealMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('VeilNote', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _navigate(const SettingsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mode Indicator ───────────────────────────────────────────
            _ModeBanner(
              isReal: isReal,
              onToggle: (val) async {
                await PracticeService.setRealMode(val);
                setState(() {});
              },
            ),
            const SizedBox(height: 24),

            // ── Quick SOS Section ────────────────────────────────────────
            _SOSButton(
              isReal:     isReal,
              triggering: _triggering,
              onTap:      _triggerEmergency,
            ),
            const SizedBox(height: 32),

            // ── Feature Grid ─────────────────────────────────────────────
            _SectionHeader(title: 'Safety Controls'),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _FeatureCard(
                  icon: Icons.mic_rounded,
                  color: AppTheme.primaryColor,
                  title: 'Audio Analysis',
                  subtitle: 'Real-time detection',
                  onTap: () => _navigate(AudioRecordingScreen(onRecordingComplete: _loadContacts)),
                ),
                _FeatureCard(
                  icon: Icons.folder_special_rounded,
                  color: AppTheme.primaryDeep,
                  title: 'Evidence',
                  subtitle: 'Secure recordings',
                  onTap: () => _navigate(const EvidenceRecorderScreen()),
                ),
                _FeatureCard(
                  icon: Icons.school_rounded,
                  color: AppTheme.emerald,
                  title: 'Practice',
                  subtitle: 'Simulate triggers',
                  onTap: () => _navigate(const PracticeModeScreen()),
                ),
                _FeatureCard(
                  icon: Icons.visibility_off_rounded,
                  color: AppTheme.rose,
                  title: 'Stealth Mode',
                  subtitle: 'Disguise app',
                  onTap: _showStealthDialog,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Emergency Network ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(title: 'Safety Network'),
                if (_contacts.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ContactListScreen()))
                        .then((_) => _loadContacts()),
                    child: const Text('Manage All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildContactSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AddContactScreen(onContactAdded: _loadContacts),
        )),
        icon: const Icon(Icons.add_moderator_rounded),
        label: const Text('Add Guardian'),
        elevation: 2,
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
    final theme = Theme.of(context);
    final baseColor = isReal ? AppTheme.rose : AppTheme.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(
          isReal ? Icons.gpp_good_rounded : Icons.psychology_rounded,
          color: baseColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isReal ? 'Active Protection' : 'Practice Mode',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: baseColor,
              ),
            ),
            Text(
              isReal ? 'Alerts are LIVE' : 'Safe to test triggers',
              style: TextStyle(
                fontSize: 12,
                color: baseColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        )),
        Switch(
          value: isReal,
          activeColor: AppTheme.rose,
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
    final theme = Theme.of(context);
    final color = isReal ? AppTheme.rose : theme.hintColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          if (isReal)
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: triggering ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color, width: 4),
            ),
            child: triggering
                ? Center(child: CircularProgressIndicator(color: color))
                : Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          triggering ? 'Sending alert…' : 'Trigger Emergency',
          style: theme.textTheme.titleLarge?.copyWith(color: color, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          isReal ? 'Push to alert all contacts' : 'Draft / Test Mode',
          style: theme.textTheme.bodyMedium,
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.1),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark 
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : AppTheme.primaryDeep,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Switch to Stealth Mode',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Toggle the notes-app disguise',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          )),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
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
    final theme = Theme.of(context);
    final hasTelegram = contact.telegramChatId != null && contact.telegramChatId!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            contact.name[0].toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${contact.relation} • ${contact.phone}',
                style: theme.textTheme.bodySmall),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Priority ${contact.priority}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )),
            ),
            const SizedBox(height: 8),
            if (hasTelegram)
              Row(children: [
                Icon(Icons.telegram, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text('Secure', style: TextStyle(fontSize: 11, color: Colors.blue[600], fontWeight: FontWeight.w600)),
              ])
            else
              Text('SMS Only', style: theme.textTheme.bodySmall),
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
