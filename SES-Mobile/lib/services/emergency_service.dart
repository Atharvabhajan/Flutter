import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'contact_service.dart';
import 'api_service.dart';
import 'practice_service.dart';

class EmergencyService {
  static Future<void> _dispatchSmsAlert(double latitude, double longitude) async {
    try {
      if (!PracticeService.isRealMode) return;
      
      final bool hasSmsPermission = await Permission.sms.isGranted;
      if (!hasSmsPermission) {
        final status = await Permission.sms.request();
        if (!status.isGranted) return;
      }

      final contacts = await ContactService.getLocalContacts();
      if (contacts.isEmpty) return;

      final message = 'EMERGENCY! I need help. My last known location is: https://maps.google.com/?q=$latitude,$longitude';
      final telephony = Telephony.instance;

      for (var contact in contacts) {
        if (contact.phone.isNotEmpty) {
          await telephony.sendSms(
            to: contact.phone,
            message: message,
          );
        }
      }
    } catch (e) {
      print('SMS Alert failed: $e');
    }
  }

  /// Trigger emergency manually with GPS location
  static Future<EmergencyResult> triggerEmergency({
    required double latitude,
    required double longitude,
    String triggerType = 'manual',
  }) async {
    if (!PracticeService.isRealMode) {
      PracticeService.triggerPracticeFeedback(triggerType);
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      return EmergencyResult(
        success: true,
        message: 'Practice Mode: Trigger intercepted successfully',
        eventId: 'practice_event_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    // Dispatch SMS alert concurrently
    _dispatchSmsAlert(latitude, longitude);

    try {
      final response = await ApiService.triggerEmergency(
        latitude: latitude,
        longitude: longitude,
        triggerType: triggerType,
      );

      return EmergencyResult(
        success: true,
        message: response['message'] ?? 'Emergency triggered successfully',
        eventId: response['data']?['event']?['eventId'],
      );
    } on ApiException catch (e) {
      return EmergencyResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Trigger silent emergency with cooldown, auto-location and retries
  static Future<void> triggerSilentEmergency({required String triggerType}) async {
    if (!PracticeService.isRealMode) {
      PracticeService.triggerPracticeFeedback(triggerType);
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]); // Vibrate twice for success
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastTriggerTime = prefs.getInt('last_trigger_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 15 seconds cooldown
    if (now - lastTriggerTime < 15000) {
      return; 
    }

    await prefs.setInt('last_trigger_time', now);
    
    // Vibrate to acknowledge trigger
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
    
    int maxRetries = 3;
    int attempt = 0;
    bool success = false;
    
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      try {
        pos = await Geolocator.getLastKnownPosition();
      } catch (e2) {
        // Continue with 0,0 if location fails to ensure event is created
        pos = null;
      }
    }

    final lat = pos?.latitude ?? 0.0;
    final lng = pos?.longitude ?? 0.0;

    while (attempt < maxRetries && !success) {
      attempt++;
      try {
        final res = await triggerEmergency(
          latitude: lat,
          longitude: lng,
          triggerType: triggerType,
        );
        if (res.success) {
          success = true;
          // Vibrate twice to confirm success
          if (await Vibration.hasVibrator() ?? false) {
            await Future.delayed(const Duration(milliseconds: 500));
            Vibration.vibrate(pattern: [0, 200, 100, 200]);
          }
        } else {
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Analyze text for threats and trigger emergency if detected
  static Future<EmergencyResult> analyzeText({
    required String text,
    double latitude = 0,
    double longitude = 0,
  }) async {
    try {
      final response = await ApiService.analyzeText(
        text: text,
        latitude: latitude,
        longitude: longitude,
      );

      if (response['isThreat'] == true) {
        _dispatchSmsAlert(latitude, longitude);
      }

      return EmergencyResult(
        success: response['isThreat'] ?? false,
        message: response['message'] ?? 'Text analysis complete',
        eventId: response['data']?['event']?['eventId'],
        threatDetected: response['isThreat'] ?? false,
        confidenceScore: (response['confidence'] as num?)?.toDouble(),
      );
    } on ApiException catch (e) {
      // If offline or failed, we can't know if it's a threat, but the user requested SMS on any alert trigger.
      // To be safe during an offline text analysis (which implies the user typed a stealth trigger), send SMS.
      _dispatchSmsAlert(latitude, longitude);
      return EmergencyResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Upload audio file and analyze for threats
  static Future<EmergencyResult> uploadAudio({
    required String filePath,
    double latitude = 0,
    double longitude = 0,
  }) async {
    try {
      final response = await ApiService.uploadAudio(
        filePath: filePath,
        latitude: latitude,
        longitude: longitude,
      );

      if (response['isThreat'] == true) {
        _dispatchSmsAlert(latitude, longitude);
      }

      return EmergencyResult(
        success: response['isThreat'] ?? false,
        message: response['message'] ?? 'Audio analysis complete',
        eventId: response['data']?['event']?['eventId'],
        threatDetected: response['isThreat'] ?? false,
        confidenceScore: (response['confidence'] as num?)?.toDouble(),
        transcription: response['transcription'],
      );
    } on ApiException catch (e) {
      // Offline audio upload implies an emergency was triggered previously or manually. Send SMS.
      _dispatchSmsAlert(latitude, longitude);
      return EmergencyResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Get all emergency events for current user
  static Future<GetEventsResult> getEmergencyEvents() async {
    try {
      final response = await ApiService.getEmergencyEvents();

      final events = (response['events'] as List?)
              ?.map((e) => EmergencyEvent.fromJson(e))
              .toList() ??
          [];

      return GetEventsResult(
        success: true,
        message: response['message'] ?? 'Events retrieved',
        events: events,
      );
    } on ApiException catch (e) {
      return GetEventsResult(
        success: false,
        message: e.message,
        events: [],
      );
    }
  }

  /// Get specific emergency event by ID
  static Future<GetEventResult> getEmergencyEvent(String eventId) async {
    try {
      final response = await ApiService.getEmergencyEvent(eventId);

      return GetEventResult(
        success: true,
        message: response['message'] ?? 'Event retrieved',
        event: EmergencyEvent.fromJson(response['event'] ?? response),
      );
    } on ApiException catch (e) {
      return GetEventResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Resolve emergency event
  static Future<EmergencyResult> resolveEmergency(String eventId) async {
    try {
      final response = await ApiService.resolveEmergency(eventId);

      return EmergencyResult(
        success: true,
        message: response['message'] ?? 'Emergency resolved',
        eventId: eventId,
      );
    } on ApiException catch (e) {
      return EmergencyResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Cancel emergency event
  static Future<EmergencyResult> cancelEmergency(String eventId) async {
    try {
      final response = await ApiService.cancelEmergency(eventId);

      return EmergencyResult(
        success: true,
        message: response['message'] ?? 'Emergency cancelled',
        eventId: eventId,
      );
    } on ApiException catch (e) {
      return EmergencyResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Upload audio file with GPS location (for automatic recording scenario)
  static Future<EmergencyResult> uploadAudioFile({
    required String filePath,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await ApiService.uploadAudio(
        filePath: filePath,
        latitude: latitude,
        longitude: longitude,
      );

      return EmergencyResult(
        success: response['success'] ?? false,
        message: response['message'] ?? 'Audio uploaded successfully',
        eventId: response['data']?['event']?['eventId'],
        threatDetected: response['isThreat'] ?? false,
        confidenceScore: (response['confidence'] as num?)?.toDouble(),
        transcription: response['transcription'],
      );
    } on ApiException catch (e) {
      return EmergencyResult(
        success: false,
        message: e.message,
      );
    }
  }
}

/// Response class for emergency operations
class EmergencyResult {
  final bool success;
  final String message;
  final String? eventId;
  final bool threatDetected;
  final double? confidenceScore;
  final String? transcription;

  EmergencyResult({
    required this.success,
    required this.message,
    this.eventId,
    this.threatDetected = false,
    this.confidenceScore,
    this.transcription,
  });
}

/// Response class for getting events
class GetEventsResult {
  final bool success;
  final String message;
  final List<EmergencyEvent> events;

  GetEventsResult({
    required this.success,
    required this.message,
    required this.events,
  });
}

/// Response class for getting single event
class GetEventResult {
  final bool success;
  final String message;
  final EmergencyEvent? event;

  GetEventResult({
    required this.success,
    required this.message,
    this.event,
  });
}

/// Model for emergency event
class EmergencyEvent {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String status; // active, resolved, cancelled
  final int alertsSent;
  final List<String> contactsNotified;
  final DateTime timestamp;

  EmergencyEvent({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.alertsSent,
    required this.contactsNotified,
    required this.timestamp,
  });

  factory EmergencyEvent.fromJson(Map<String, dynamic> json) {
    return EmergencyEvent(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      latitude: (json['location']?['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['location']?['longitude'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'active',
      alertsSent: json['alertsSent'] ?? 0,
      contactsNotified: List<String>.from(json['contactsNotified'] ?? []),
      timestamp:
          DateTime.tryParse(json['timestamp'] ?? json['createdAt'] ?? '') ??
              DateTime.now(),
    );
  }
}
