import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';
import '../services/stealth_mode_service.dart';
import '../services/emergency_service.dart';
import '../services/audio_upload_queue.dart';
import '../config/app_theme.dart';

class StealthNotesScreen extends StatefulWidget {
  const StealthNotesScreen({Key? key}) : super(key: key);

  @override
  State<StealthNotesScreen> createState() => _StealthNotesScreenState();
}

class _StealthNotesScreenState extends State<StealthNotesScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();

  bool   _isRecording  = false;
  bool   _triggering   = false;
  Timer? _maxDurTimer;
  String _recordingPath = '';  // Track recording file path

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _maxDurTimer?.cancel();
    _controller.dispose();
    if (_isRecording) _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  // ── Real-time keyword & phrase detection ───────────────────────────────────
  void _onTextChanged() async {
    final text = _controller.text;
    if (text.isEmpty) return;

    final lower = text.toLowerCase();

    // 1. Secret Unlock Phrase
    final phrase = StealthModeService.secretPhrase;
    if (phrase.isNotEmpty && text.endsWith(phrase)) {
      _vibrate(100);
      _controller.clear();
      StealthModeService.exitDisguise();
      return;
    }

    // 2. Alert Keyword
    final alertKw = StealthModeService.alertKeyword;
    if (alertKw.isNotEmpty && lower.endsWith(alertKw)) {
      _vibrate(200);
      _removeKeywordFromController(alertKw);
      _triggerEmergency();
      return;
    }

    // 3. Audio Start Keyword
    final startKw = StealthModeService.recordStartKeyword;
    if (startKw.isNotEmpty && lower.endsWith(startKw) && !_isRecording) {
      _vibrate(150);
      _removeKeywordFromController(startKw);
      _startRecording();
      return;
    }

    // 4. Audio Stop Keyword
    final stopKw = StealthModeService.recordStopKeyword;
    if (stopKw.isNotEmpty && lower.endsWith(stopKw) && _isRecording) {
      _vibrate(100);
      Future.delayed(const Duration(milliseconds: 150), () => _vibrate(100)); // Double pulse
      _removeKeywordFromController(stopKw);
      _stopRecording();
      return;
    }
  }

  void _vibrate(int duration) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration);
    }
  }

  void _removeKeywordFromController(String keyword) {
    final text = _controller.text;
    if (text.toLowerCase().endsWith(keyword)) {
      final newText = text.substring(0, text.length - keyword.length).trimRight();
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  // ── Save button ───────────────────────────────────────────────────────────────
  Future<void> _onSave() async {
    // Manual save only saves the text state, keywords are processed real-time
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved successfully'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Redundant keyword processing removed. Triggers are now real-time.

  // ── Silent emergency dispatch ─────────────────────────────────────────────────
  Future<void> _triggerEmergency() async {
    if (_triggering) return;
    _triggering = true;
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
      await EmergencyService.triggerEmergency(
        latitude:    pos?.latitude  ?? 0.0,
        longitude:   pos?.longitude ?? 0.0,
        triggerType: 'manual',
      );
    } catch (_) {
      // Fail silently
    } finally {
      _triggering = false;
    }
  }

  // ── Audio recording ───────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      final dir  = await getApplicationDocumentsDirectory();
      final now  = DateTime.now();
      // Filename starts with 'evidence_' so it appears in the Evidence section
      final name = 'evidence_${now.year}-${_p(now.month)}-${_p(now.day)}'
                   '_${_p(now.hour)}-${_p(now.minute)}-${_p(now.second)}.m4a';
      final path = '${dir.path}/$name';
      _recordingPath = path;

      await _recorder.start(
        const RecordConfig(
          encoder:    AudioEncoder.aacLc,
          bitRate:    128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() => _isRecording = true);

      // Auto-stop after 10 minutes max for stealth recording
      _maxDurTimer = Timer(const Duration(minutes: 10), () {
        if (_isRecording) _stopRecording();
      });
    } catch (_) {
      // Fail silently in stealth mode
    }
  }

  Future<void> _stopRecording() async {
    try {
      _maxDurTimer?.cancel();
      await _recorder.stop();
      setState(() => _isRecording = false);

      if (_recordingPath.isNotEmpty) {
        // Capture GPS at the moment recording stops so the upload queue
        // sends real coordinates to the backend (fixes bug: always 0,0).
        double lat = 0.0, lng = 0.0;
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 4),
          );
          lat = pos.latitude;
          lng = pos.longitude;
        } catch (_) {
          try {
            final last = await Geolocator.getLastKnownPosition();
            if (last != null) { lat = last.latitude; lng = last.longitude; }
          } catch (_) {}
        }

        unawaited(AudioUploadQueue.handleRecordingComplete(
          _recordingPath,
          latitude:  lat,
          longitude: lng,
        ));
      }
    } catch (_) {
      setState(() => _isRecording = false);
    }
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  // ── UI ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notes',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: _onSave,
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Type your notes here...',
              hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.4)),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              filled: false,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 18,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onSave,
        backgroundColor: isDark ? AppTheme.amber : Colors.amber[700],
        elevation: 4,
        child: const Icon(Icons.edit_note_rounded, color: Colors.white),
      ),
    );
  }
}
