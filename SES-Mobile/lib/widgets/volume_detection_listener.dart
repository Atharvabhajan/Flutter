import 'package:flutter/material.dart';
import '../services/protect_mode_controller.dart';
import '../services/volume_listener_service.dart';

class VolumeDetectionListener extends StatefulWidget {
  final Widget child;
  final Function(bool success, String message)? onEmergencyTriggered;

  const VolumeDetectionListener({
    Key? key,
    required this.child,
    this.onEmergencyTriggered,
  }) : super(key: key);

  @override
  State<VolumeDetectionListener> createState() =>
      _VolumeDetectionListenerState();
}

class _VolumeDetectionListenerState extends State<VolumeDetectionListener> {

  @override
  void initState() {
    super.initState();
    _initializeVolumeDetection();
  }

  void _initializeVolumeDetection() {
    ProtectModeController().initialize();
    VolumeListenerService().initialize();
  }

  void _showEmergencyFeedback(bool success, String message) {
    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ $message' : '❌ $message'),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );

    // Show visual indicator if emergency triggered
    if (success && message.contains('triggered')) {
      _showEmergencyAlert();
    }
  }

  void _showEmergencyAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Text(
          '🚨 EMERGENCY ACTIVATED',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Emergency alert has been triggered!',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Audio recording and location data are being sent to emergency contacts.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.red[300]),
              minHeight: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    // Auto-close after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    ProtectModeController().dispose();
    VolumeListenerService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
