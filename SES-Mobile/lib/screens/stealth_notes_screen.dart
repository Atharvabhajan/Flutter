import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';
import '../services/stealth_mode_service.dart';
import '../services/emergency_service.dart';
import '../services/audio_upload_queue.dart';

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

  // ── Real-time unlock phrase detection ────────────────────────────────────────
  void _onTextChanged() async {
    final text   = _controller.text;
    final phrase = StealthModeService.secretPhrase;
    if (phrase.isNotEmpty && text.endsWith(phrase)) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }
      _controller.clear();
      StealthModeService.disableStealthMode();
    }
  }

  // ── Save button ───────────────────────────────────────────────────────────────
  Future<void> _onSave() async {
    final input = _controller.text.trim();
    await _processStealthInput(input);
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

  // ── Core keyword processing ───────────────────────────────────────────────────
  Future<void> _processStealthInput(String input) async {
    if (input.isEmpty) return;
    final lower = input.toLowerCase();

    final startKw = StealthModeService.recordStartKeyword;
    final stopKw  = StealthModeService.recordStopKeyword;

    // Case 1: start recording audio (via keyword in notes)
    if (startKw.isNotEmpty && lower.contains(startKw) && !_isRecording) {
      await _startRecording();
      return;
    }

    // Case 2: stop recording audio (via keyword in notes)
    if (stopKw.isNotEmpty && lower.contains(stopKw) && _isRecording) {
      await _stopRecording();
      return;
    }
  }

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
      final name = 'stealth_${now.year}-${_p(now.month)}-${_p(now.day)}'
                   '_${_p(now.hour)}-${_p(now.minute)}-${_p(now.second)}.m4a';
      final path = '${dir.path}/$name';
      _recordingPath = path;  // ← Store path for later upload

      await _recorder.start(
        const RecordConfig(
          encoder:    AudioEncoder.aacLc,
          bitRate:    128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _isRecording = true;

      // Auto-stop after 5 minutes max
      _maxDurTimer = Timer(const Duration(minutes: 5), () {
        if (_isRecording) _stopRecording();
      });
    } catch (_) {
      // Fail silently
    }
  }

  Future<void> _stopRecording() async {
    try {
      _maxDurTimer?.cancel();
      await _recorder.stop();
      _isRecording = false;

      // Handle upload with retry queue
      if (_recordingPath.isNotEmpty) {
        unawaited(AudioUploadQueue.handleRecordingComplete(_recordingPath));
      }
    } catch (_) {
      _isRecording = false;
    }
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  // ── UI ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notes', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
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
            decoration: const InputDecoration(
              hintText: 'Type your notes here...',
              hintStyle: TextStyle(color: Colors.black26),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 17,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onSave,
        backgroundColor: Colors.yellow[700],
        child: const Icon(Icons.save_outlined, color: Colors.white),
      ),
    );
  }
}
