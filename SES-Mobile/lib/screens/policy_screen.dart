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
            content: const Text('Silent Emergency Shield requires Location and Microphone access to function properly. Please enable them in settings if permanently denied.'),
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Security Setup',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Before using Silent Emergency Shield, please understand how we use device features to keep you safe.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.hintColor,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  children: const [
                    _PolicyItem(
                      icon: Icons.location_on,
                      title: 'Location Access',
                      description: 'Used to send your live location during emergencies.',
                    ),
                    _PolicyItem(
                      icon: Icons.mic,
                      title: 'Microphone Access',
                      description: 'Used for voice-based threat detection.',
                    ),
                    _PolicyItem(
                      icon: Icons.run_circle,
                      title: 'Background Execution',
                      description: 'Ensures emergency triggers work even when the app is closed.',
                    ),
                  ],
                ),
              ),
              if (!_permissionsGranted)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _requestPermissions,
                    icon: const Icon(Icons.security),
                    label: const Text('Grant Required Permissions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              if (_permissionsGranted)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('All required permissions granted', 
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged: (val) {
                      setState(() {
                        _isAgreed = val ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'I agree to the privacy policy and emergency audio recording',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Continue',
                  onPressed: (_isAgreed && _permissionsGranted) ? _onContinue : () {},
                ),
              ),
              const SizedBox(height: 10),
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
