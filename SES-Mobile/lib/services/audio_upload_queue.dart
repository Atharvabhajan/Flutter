import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'emergency_service.dart';

class AudioUploadQueue {
  static const String _queueKey = 'pending_audio_uploads';
  static const int _maxQueueSize = 10;
  static const int _maxRetries = 3;

  static List<Map<String, dynamic>> _queue = [];
  static SharedPreferences? _prefs;

  // ── Initialization ────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadQueue();
    if (kDebugMode) {
      print('[AudioUploadQueue] Initialized with ${_queue.length} pending uploads');
    }
  }

  // ── Load queue from SharedPreferences ─────────────────────────────────────────
  static Future<void> _loadQueue() async {
    try {
      final jsonStr = _prefs?.getString(_queueKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _queue = List<Map<String, dynamic>>.from(
          decoded.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      } else {
        _queue = [];
      }
    } catch (e) {
      if (kDebugMode) print('[AudioUploadQueue] Error loading queue: $e');
      _queue = [];
    }
  }

  // ── Save queue to SharedPreferences ───────────────────────────────────────────
  static Future<void> _saveQueue() async {
    try {
      final jsonStr = jsonEncode(_queue);
      await _prefs?.setString(_queueKey, jsonStr);
    } catch (e) {
      if (kDebugMode) print('[AudioUploadQueue] Error saving queue: $e');
    }
  }

  // ── Entry point: Handle recording complete ────────────────────────────────────
  // Callers should pass the GPS coordinates captured at recording time.
  // Passing 0.0/0.0 is still accepted for backwards compatibility but creates
  // emergency events with no location on the backend.
  static Future<void> handleRecordingComplete(
    String filePath, {
    double latitude  = 0.0,
    double longitude = 0.0,
  }) async {
    if (filePath.isEmpty) return;

    // Try immediate upload (fire-and-forget), passing coordinates through
    unawaited(_uploadSingleFile(filePath, 0, latitude: latitude, longitude: longitude));
  }

  // ── Add to pending uploads ────────────────────────────────────────────────────
  // Coordinates captured at recording time are stored so they survive app restarts.
  static Future<void> addToPendingUploads(
    String filePath, {
    double latitude  = 0.0,
    double longitude = 0.0,
  }) async {
    // Avoid duplicates
    final exists = _queue.any((item) => item['filePath'] == filePath);
    if (exists) {
      if (kDebugMode) print('[AudioUploadQueue] File already in queue: $filePath');
      return;
    }

    // Enforce max queue size: remove oldest if at limit
    if (_queue.length >= _maxQueueSize) {
      final oldest = _queue.removeAt(0);
      if (kDebugMode) print('[AudioUploadQueue] Queue full, removed oldest: ${oldest['filePath']}');
      // Optionally delete the file
      try {
        await File(oldest['filePath']).delete();
      } catch (_) {}
    }

    // Add new entry — store coordinates so they survive across app restarts
    _queue.add({
      'filePath' : filePath,
      'retries'  : 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'latitude' : latitude,
      'longitude': longitude,
    });

    await _saveQueue();

    if (kDebugMode) {
      print('[AudioUploadQueue] Added to queue: $filePath (total: ${_queue.length})');
    }
  }

  // ── Remove from pending uploads ───────────────────────────────────────────────
  static Future<void> removePendingUpload(String filePath) async {
    _queue.removeWhere((item) => item['filePath'] == filePath);
    await _saveQueue();

    if (kDebugMode) print('[AudioUploadQueue] Removed from queue: $filePath');
  }

  // ── Retry all pending uploads ─────────────────────────────────────────────────
  static Future<void> retryPendingUploads() async {
    if (_queue.isEmpty) {
      if (kDebugMode) print('[AudioUploadQueue] No pending uploads to retry');
      return;
    }

    if (kDebugMode) print('[AudioUploadQueue] Retrying ${_queue.length} pending uploads...');

    // Create a copy to iterate (queue can change during iteration)
    final queueCopy = List<Map<String, dynamic>>.from(_queue);

    for (final item in queueCopy) {
      final filePath  = item['filePath']  as String;
      final retries   = item['retries']   as int;
      final latitude  = (item['latitude']  as num?)?.toDouble() ?? 0.0;
      final longitude = (item['longitude'] as num?)?.toDouble() ?? 0.0;

      await _uploadSingleFile(
        filePath, retries,
        latitude: latitude, longitude: longitude,
      );
    }
  }

  // ── Upload single file with retry logic ───────────────────────────────────────
  static Future<void> _uploadSingleFile(
    String filePath,
    int currentRetries, {
    double latitude  = 0.0,
    double longitude = 0.0,
  }) async {
    try {
      // Check if file exists
      final file = File(filePath);
      if (!file.existsSync()) {
        if (kDebugMode) print('[AudioUploadQueue] File not found, removing: $filePath');
        await removePendingUpload(filePath);
        return;
      }

      // Attempt upload — include GPS coordinates captured at recording time
      if (kDebugMode) print('[AudioUploadQueue] Uploading: $filePath (retry $currentRetries)');

      final result = await EmergencyService.uploadAudio(
        filePath:  filePath,
        latitude:  latitude,
        longitude: longitude,
      );

      if (result.success) {
        if (kDebugMode) print('[AudioUploadQueue] Upload successful: $filePath');
        await removePendingUpload(filePath);
        // Delete local file after successful upload
        try {
          await file.delete();
        } catch (_) {}
        return;
      }

      // Upload failed: handle retry
      _handleUploadFailure(filePath, currentRetries);
    } catch (e) {
      if (kDebugMode) print('[AudioUploadQueue] Upload error: $e');
      _handleUploadFailure(filePath, currentRetries);
    }
  }

  // ── Handle upload failure: retry or discard ───────────────────────────────────
  static void _handleUploadFailure(String filePath, int currentRetries) {
    final nextRetry = currentRetries + 1;

    if (nextRetry > _maxRetries) {
      if (kDebugMode) {
        print('[AudioUploadQueue] Max retries exceeded for: $filePath');
      }
      // Discard file
      unawaited(removePendingUpload(filePath));
      try {
        File(filePath).deleteSync();
      } catch (_) {}
      return;
    }

    // Update retry count and save
    final itemIndex = _queue.indexWhere((item) => item['filePath'] == filePath);
    if (itemIndex >= 0) {
      _queue[itemIndex]['retries'] = nextRetry;
      unawaited(_saveQueue());
      if (kDebugMode) {
        print('[AudioUploadQueue] Retry count updated: $filePath (retry $nextRetry)');
      }
    }
  }

  // ── Get pending count (for debugging) ──────────────────────────────────────────
  static int getPendingCount() => _queue.length;

  // ── Clear all (debug only) ────────────────────────────────────────────────────
  @visibleForTesting
  static Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
  }
}
