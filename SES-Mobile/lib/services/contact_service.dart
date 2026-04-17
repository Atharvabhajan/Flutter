import 'api_service.dart';

class ContactService {
  /// Add a new emergency contact
  static Future<ContactResult> addContact({
    required String name,
    required String phone,
    required String relation,
    String? email,
    String? telegramChatId,
    int priority = 1,
  }) async {
    try {
      final response = await ApiService.addContact(
        name: name,
        phone: phone,
        relation: relation,
        email: email,
        telegramChatId: telegramChatId,
        priority: priority,
      );

      return ContactResult(
        success: true,
        message: response['message'] ?? 'Contact added successfully',
        contactId: response['data']?['_id'] ?? response['_id'],
      );
    } on ApiException catch (e) {
      return ContactResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Get all emergency contacts
  static Future<GetContactsResult> getContacts() async {
    try {
      final response = await ApiService.getContacts();

      final data = response['data'] as Map<String, dynamic>?;
      final contacts = (data?['items'] as List?)
              ?.map((c) => EmergencyContact.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [];

      return GetContactsResult(
        success: true,
        message: response['message'] ?? 'Contacts retrieved',
        contacts: contacts,
      );
    } on ApiException catch (e) {
      return GetContactsResult(
        success: false,
        message: e.message,
        contacts: [],
      );
    }
  }

  /// Update an emergency contact
  static Future<ContactResult> updateContact({
    required String contactId,
    required String name,
    required String phone,
    required String relation,
    String? email,
    String? telegramChatId,
    int priority = 1,
  }) async {
    try {
      final response = await ApiService.updateContact(
        contactId: contactId,
        name: name,
        phone: phone,
        relation: relation,
        email: email,
        telegramChatId: telegramChatId,
        priority: priority,
      );

      return ContactResult(
        success: true,
        message: response['message'] ?? 'Contact updated successfully',
        contactId: contactId,
      );
    } on ApiException catch (e) {
      return ContactResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Delete an emergency contact
  static Future<ContactResult> deleteContact(String contactId) async {
    try {
      final response = await ApiService.deleteContact(contactId);

      return ContactResult(
        success: true,
        message: response['message'] ?? 'Contact deleted successfully',
        contactId: contactId,
      );
    } on ApiException catch (e) {
      return ContactResult(
        success: false,
        message: e.message,
      );
    }
  }
}

/// Response class for contact operations
class ContactResult {
  final bool success;
  final String message;
  final String? contactId;

  ContactResult({
    required this.success,
    required this.message,
    this.contactId,
  });
}

/// Response class for getting contacts
class GetContactsResult {
  final bool success;
  final String message;
  final List<EmergencyContact> contacts;

  GetContactsResult({
    required this.success,
    required this.message,
    required this.contacts,
  });
}

/// Model for emergency contact
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation;
  final String? email;
  final String? telegramChatId;
  final int priority;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    this.email,
    this.telegramChatId,
    required this.priority,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relation: json['relation'] ?? '',
      email: json['email'],
      telegramChatId: json['telegramChatId'],
      priority: json['priority'] ?? 1,
    );
  }
}
