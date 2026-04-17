import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/evidence_service.dart';

class EvidenceRecorderScreen extends StatefulWidget {
  const EvidenceRecorderScreen({Key? key}) : super(key: key);

  @override
  State<EvidenceRecorderScreen> createState() => _EvidenceRecorderScreenState();
}

class _EvidenceRecorderScreenState extends State<EvidenceRecorderScreen> {
  // ─── Auth ───────────────────────────────────────────────────────────────────
  bool _isAuthenticated = false;
  bool _hasPhrase       = false;
  bool _checkingAuth    = true;
  bool _obscurePhrase   = true;

  final _phraseController = TextEditingController();

  // ─── Recording ──────────────────────────────────────────────────────────────
  bool   _isRecording      = false;
  int    _elapsedSeconds   = 0;
  Timer? _durationTimer;

  // ─── Playback ───────────────────────────────────────────────────────────────
  final _player     = AudioPlayer();
  String? _playingPath;

  // ─── Recordings list ────────────────────────────────────────────────────────
  List<EvidenceFile> _recordings    = [];
  bool               _loadingFiles  = false;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initAuth();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingPath = null);
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _player.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  // ─── Auth Logic ─────────────────────────────────────────────────────────────

  Future<void> _initAuth() async {
    final has = await EvidenceService.hasPhrase();
    setState(() {
      _hasPhrase    = has;
      _checkingAuth = false;
    });
  }

  Future<void> _submitPhrase() async {
    final input = _phraseController.text;
    if (input.trim().isEmpty) return;

    if (!_hasPhrase) {
      await EvidenceService.setPhrase(input);
      setState(() { _hasPhrase = true; _isAuthenticated = true; });
      _loadRecordings();
      return;
    }

    final ok = await EvidenceService.verifyPhrase(input);
    if (ok) {
      setState(() => _isAuthenticated = true);
      _loadRecordings();
    } else {
      _phraseController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect phrase. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Recording Logic ────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_isRecording) return;
    final path = await EvidenceService.startRecording();
    if (path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    setState(() {
      _isRecording    = true;
      _elapsedSeconds = 0;
    });
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _durationTimer?.cancel();
    await EvidenceService.stopRecording();
    setState(() {
      _isRecording    = false;
      _elapsedSeconds = 0;
    });
    await _loadRecordings();
  }

  // ─── Playback Logic ─────────────────────────────────────────────────────────

  Future<void> _togglePlay(EvidenceFile file) async {
    if (_playingPath == file.path) {
      await _player.stop();
      setState(() => _playingPath = null);
      return;
    }
    await _player.stop();
    await _player.play(DeviceFileSource(file.path));
    setState(() => _playingPath = file.path);
  }

  // ─── File Logic ─────────────────────────────────────────────────────────────

  Future<void> _loadRecordings() async {
    setState(() => _loadingFiles = true);
    final list = await EvidenceService.getRecordings();
    setState(() {
      _recordings  = list;
      _loadingFiles = false;
    });
  }

  Future<void> _confirmDelete(EvidenceFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text('Delete "${file.name}"?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (_playingPath == file.path) {
      await _player.stop();
      setState(() => _playingPath = null);
    }
    await EvidenceService.deleteRecording(file.path);
    await _loadRecordings();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${_p(dt.month)}-${_p(dt.day)}  ${_p(dt.hour)}:${_p(dt.minute)}';

  String _p(int n) => n.toString().padLeft(2, '0');

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isAuthenticated ? _buildMain() : _buildLockScreen();
  }

  // ── Lock Screen ─────────────────────────────────────────────────────────────

  Widget _buildLockScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence Recorder')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _hasPhrase ? 'Enter Secret Phrase' : 'Set a Secret Phrase',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _hasPhrase
                    ? 'Enter your phrase to access recordings.'
                    : 'Create a phrase to protect your evidence recordings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 32),
              TextField(
                controller:   _phraseController,
                obscureText:  _obscurePhrase,
                decoration: InputDecoration(
                  labelText:   _hasPhrase ? 'Secret Phrase' : 'New Secret Phrase',
                  border: const OutlineInputBorder(),
                  prefixIcon:  const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePhrase ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePhrase = !_obscurePhrase),
                  ),
                ),
                onSubmitted: (_) => _submitPhrase(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitPhrase,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _hasPhrase ? 'Unlock' : 'Set Phrase & Enter',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main Screen ─────────────────────────────────────────────────────────────

  Widget _buildMain() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence Recorder'),
        actions: [
          IconButton(
            icon:     const Icon(Icons.refresh),
            tooltip:  'Refresh',
            onPressed: _loadRecordings,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecorderCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Text(
                  'Saved Recordings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_recordings.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${_recordings.length})',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── Recorder Card ───────────────────────────────────────────────────────────

  Widget _buildRecorderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: _isRecording ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecording ? Colors.red.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              key: ValueKey(_isRecording),
              size: 56,
              color: _isRecording ? Colors.red : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording ? 'Recording in progress' : 'Ready to record',
            style: TextStyle(
              fontSize: 14,
              color: _isRecording ? Colors.red[700] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(_elapsedSeconds),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: _isRecording ? Colors.red[700] : Colors.grey[300],
            ),
          ),
          const SizedBox(height: 20),
          _isRecording
              ? ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon:  const Icon(Icons.stop_rounded),
                  label: const Text('Stop Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon:  const Icon(Icons.fiber_manual_record),
                  label: const Text('Start Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Recordings List ─────────────────────────────────────────────────────────

  Widget _buildList() {
    if (_loadingFiles) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No recordings yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Start Recording" to begin.',
              style: TextStyle(color: Colors.grey[350], fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _recordings.length,
      itemBuilder: (_, i) {
        final file      = _recordings[i];
        final isPlaying = _playingPath == file.path;
        return Card(
          margin:    const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor:
                  isPlaying ? Colors.blue.shade50 : Colors.grey.shade100,
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? Colors.blue : Colors.grey[600],
              ),
            ),
            title: Text(
              file.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _fmtDate(file.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon:     Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.blue,
                  ),
                  tooltip:  isPlaying ? 'Pause' : 'Play',
                  onPressed: () => _togglePlay(file),
                ),
                IconButton(
                  icon:     const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip:  'Delete',
                  onPressed: () => _confirmDelete(file),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
