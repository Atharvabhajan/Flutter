import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class EvidenceFile {
  final String path;
  final String name;
  final DateTime timestamp;

  EvidenceFile({
    required this.path,
    required this.name,
    required this.timestamp,
  });
}

class EvidenceService {
  static const _storage   = FlutterSecureStorage();
  static const _phraseKey = 'evidence_secret_phrase';
  static final _recorder  = AudioRecorder();

  static bool _isRecording = false;
  static bool get isRecording => _isRecording;

  // ─── Phrase Management ────────────────────────────────────────────────────

  static Future<bool> hasPhrase() async {
    final v = await _storage.read(key: _phraseKey);
    return v != null && v.isNotEmpty;
  }

  static Future<void> setPhrase(String phrase) async {
    await _storage.write(key: _phraseKey, value: phrase.trim());
  }

  static Future<bool> verifyPhrase(String input) async {
    final stored = await _storage.read(key: _phraseKey);
    return stored == input.trim();
  }

  // ─── Recording ────────────────────────────────────────────────────────────

  static Future<String?> startRecording() async {
    if (_isRecording) return null;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;

    final dir  = await getApplicationDocumentsDirectory();
    final now  = DateTime.now();
    final name = 'evidence_${now.year}-${_p(now.month)}-${_p(now.day)}_${_p(now.hour)}-${_p(now.minute)}-${_p(now.second)}.m4a';
    final path = '${dir.path}/$name';

    await _recorder.start(
      const RecordConfig(
        encoder:    AudioEncoder.aacLc,
        bitRate:    128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _isRecording = true;
    return path;
  }

  static Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  // ─── File Management ──────────────────────────────────────────────────────

  static Future<List<EvidenceFile>> getRecordings() async {
    final dir   = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('/evidence_') && f.path.endsWith('.m4a'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files.map((f) {
      final name = f.uri.pathSegments.last;
      return EvidenceFile(
        path:      f.path,
        name:      name,
        timestamp: f.lastModifiedSync(),
      );
    }).toList();
  }

  static Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _p(int n) => n.toString().padLeft(2, '0');
}
