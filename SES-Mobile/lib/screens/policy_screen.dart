import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import '../services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart'; // For MainApp routing

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({Key? key}) : super(key: key);

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  bool _isAgreed = false;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  void _checkInitialPermissions() async {
    final granted = await PermissionService.hasRequiredPermissions();
    if (mounted) {
      setState(() => _permissionsGranted = granted);
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await PermissionService.requestEmergencyPermissions();
    if (granted) {
      setState(() => _permissionsGranted = true);
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text('VeilNote requires Location and Microphone access to function properly. Please enable them in settings if permanently denied.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _onContinue() async {
    if (!_permissionsGranted) {
      await _requestPermissions();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Security Setup',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Before using VeilNote, please understand how we use device features to keep you safe.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _PolicyItem(
                      icon: Icons.location_on_rounded,
                      title: 'Location Access',
                      description: 'Used to send your live location during emergencies.',
                    ),
                    _PolicyItem(
                      icon: Icons.mic_rounded,
                      title: 'Microphone Access',
                      description: 'Used for voice-based threat detection.',
                    ),
                    _PolicyItem(
                      icon: Icons.offline_bolt_rounded,
                      title: 'Background Stability',
                      description: 'Ensures safety triggers work even when the app is minimized.',
                    ),
                  ],
                ),
              ),
              
              // ── Permission Status ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _permissionsGranted 
                    ? AppTheme.emerald.withValues(alpha: 0.1)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _permissionsGranted 
                      ? AppTheme.emerald.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _permissionsGranted ? Icons.check_circle_rounded : Icons.security_rounded,
                      color: _permissionsGranted ? AppTheme.emerald : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _permissionsGranted 
                          ? 'All systems ready. You are protected.' 
                          : 'Vehicle requires security permissions to start shielding.',
                        style: TextStyle(
                          color: _permissionsGranted ? AppTheme.emerald : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!_permissionsGranted)
                      TextButton(
                        onPressed: _requestPermissions,
                        child: const Text('Grant'),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ── Agreement ──────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged: (val) => setState(() => _isAgreed = val ?? false),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: Text(
                      'I understand and agree to the protection protocols',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Initialize VeilNote',
                onPressed: (_isAgreed && _permissionsGranted) ? _onContinue : () {},
                backgroundColor: (_isAgreed && _permissionsGranted) ? null : theme.hintColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PolicyItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
