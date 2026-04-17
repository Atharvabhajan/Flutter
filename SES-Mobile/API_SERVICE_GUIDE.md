# API Service Integration Guide

## Overview

The `ApiService` class provides a centralized, type-safe interface for all API communication with the backend. It handles:

- JWT token management and automatic authorization headers
- Request/response serialization
- Error handling with `ApiException`
- Timeout management
- Multipart file uploads

## Key Features

### ✅ Centralized API Access

All API calls go through `ApiService`, ensuring consistent error handling and token management.

### ✅ Automatic JWT Token Handling

Tokens are automatically injected into the `Authorization: Bearer <token>` header for all protected endpoints.

### ✅ Consistent Error Handling

All errors are wrapped in `ApiException` with meaningful messages and HTTP status codes.

### ✅ Type-Safe Responses

Each service returns strongly-typed result objects instead of generic `Map<String, dynamic>`.

### ✅ Timeout Protection

All requests have a 30-second timeout to prevent hanging requests.

---

## Services Architecture

```
┌─────────────────────────────────────────┐
│         Screen/UI Component             │
├─────────────────────────────────────────┤
│  AuthService  |  EmergencyService       │
│  ContactService                         │
├─────────────────────────────────────────┤
│              ApiService                 │
│  (Centralized API & Token Management)   │
├─────────────────────────────────────────┤
│          HTTP Client + JWT              │
│  (Bearer Token Injection)               │
├─────────────────────────────────────────┤
│            Backend API                  │
│  (Express.js + MongoDB)                 │
└─────────────────────────────────────────┘
```

---

## Authentication Service

### Register a New User

```dart
final result = await AuthService.register(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'SecurePassword123',
  phone: '1234567890',
);

if (result.success) {
  print('Registration successful: ${result.message}');
} else {
  print('Registration failed: ${result.message}');
}
```

### Login User

```dart
final result = await AuthService.login(
  email: 'john@example.com',
  password: 'SecurePassword123',
);

if (result.success) {
  print('Login successful');
  // Token is automatically saved
} else {
  print('Login error: ${result.message}');
}
```

### Get User Data

```dart
// After login, retrieve saved user data
final userData = await AuthService.getUserData();
print('User: ${userData?['name']}');
print('Email: ${userData?['email']}');
```

### Check Login Status

```dart
final isLoggedIn = await AuthService.isLoggedIn();
if (isLoggedIn) {
  // Show home screen
} else {
  // Show login screen
}
```

### Logout

```dart
await AuthService.logout();
// Clears token and user data
```

---

## Emergency Service

### Trigger Emergency

```dart
import 'package:geolocator/geolocator.dart';

final position = await Geolocator.getCurrentPosition();

final result = await EmergencyService.triggerEmergency(
  latitude: position.latitude,
  longitude: position.longitude,
);

if (result.success) {
  print('🚨 Emergency triggered!');
  print('Event ID: ${result.eventId}');
} else {
  print('Failed: ${result.message}');
}
```

### Analyze Text for Threats

```dart
final result = await EmergencyService.analyzeText(
  text: 'Help! I need assistance immediately.',
  latitude: 40.7128,
  longitude: -74.0060,
);

if (result.threatDetected) {
  print('🚨 THREAT DETECTED!');
  print('Confidence: ${result.confidenceScore}%');
} else {
  print('✓ No threat detected');
}
```

### Upload and Analyze Audio

```dart
final result = await EmergencyService.uploadAudio(
  filePath: '/path/to/audio.wav',
  latitude: 40.7128,
  longitude: -74.0060,
);

if (result.threatDetected) {
  print('🚨 Threat detected in audio');
  print('Transcription: ${result.transcription}');
}
```

### Get All Emergency Events

```dart
final result = await EmergencyService.getEmergencyEvents();

if (result.success) {
  for (final event in result.events) {
    print('Event: ${event.id}');
    print('Status: ${event.status}');
    print('Alerts Sent: ${event.alertsSent}');
  }
} else {
  print('Failed to fetch events: ${result.message}');
}
```

### Get Specific Event

```dart
final result = await EmergencyService.getEmergencyEvent('event-id-123');

if (result.success && result.event != null) {
  final event = result.event!;
  print('Location: ${event.latitude}, ${event.longitude}');
  print('Contacts Notified: ${event.contactsNotified.length}');
}
```

### Resolve Emergency

```dart
final result = await EmergencyService.resolveEmergency('event-id-123');

if (result.success) {
  print('Emergency resolved');
}
```

### Cancel Emergency

```dart
final result = await EmergencyService.cancelEmergency('event-id-123');

if (result.success) {
  print('Emergency cancelled');
}
```

---

## Contact Service

### Add Contact

```dart
final result = await ContactService.addContact(
  name: 'Mom',
  phone: '1234567890',
  relation: 'Family',
  email: 'mom@example.com',
  priority: 1,
);

if (result.success) {
  print('Contact added: ${result.contactId}');
} else {
  print('Failed: ${result.message}');
}
```

### Get All Contacts

```dart
final result = await ContactService.getContacts();

if (result.success) {
  for (final contact in result.contacts) {
    print('${contact.name} (${contact.relation}): ${contact.phone}');
  }
} else {
  print('Failed: ${result.message}');
}
```

### Update Contact

```dart
final result = await ContactService.updateContact(
  contactId: 'contact-id-123',
  name: 'Mom',
  phone: '9876543210',
  relation: 'Family',
  priority: 1,
);

if (result.success) {
  print('Contact updated');
}
```

### Delete Contact

```dart
final result = await ContactService.deleteContact('contact-id-123');

if (result.success) {
  print('Contact deleted');
}
```

---

## Direct API Service Usage

For advanced use cases, you can use `ApiService` directly:

```dart
try {
  // Raw API call
  final response = await ApiService.triggerEmergency(
    latitude: 40.7128,
    longitude: -74.0060,
  );

  print(response); // Raw response map
} on ApiException catch (e) {
  print('Error: ${e.message}');
  print('Status Code: ${e.statusCode}');
}
```

---

## Error Handling

### API Exceptions

All API errors throw `ApiException` with helpful error messages:

```dart
try {
  await AuthService.login(
    email: 'user@example.com',
    password: 'password',
  );
} on ApiException catch (e) {
  switch (e.statusCode) {
    case 401:
      print('Unauthorized: ${e.message}');
      break;
    case 403:
      print('Forbidden: ${e.message}');
      break;
    case 404:
      print('Not found: ${e.message}');
      break;
    case 409:
      print('Conflict: ${e.message}');
      break;
    case 500:
      print('Server error: ${e.message}');
      break;
    default:
      print('Error: ${e.message}');
  }
}
```

### Common Error Codes

| Code | Meaning      | Action                                |
| ---- | ------------ | ------------------------------------- |
| 200  | Success      | Operation completed successfully      |
| 201  | Created      | Resource created successfully         |
| 400  | Bad Request  | Check your input parameters           |
| 401  | Unauthorized | Login required or token expired       |
| 403  | Forbidden    | You don't have permission             |
| 404  | Not Found    | Resource not found                    |
| 409  | Conflict     | Resource already exists (e.g., email) |
| 500  | Server Error | Backend error, try again later        |

---

## Token Management

### Automatic Token Handling

Tokens are automatically managed by `ApiService`:

```dart
// 1. Login - token is automatically saved
await AuthService.login(email: 'user@example.com', password: 'pass');

// 2. Make protected API calls - token is automatically injected
await ContactService.getContacts(); // Bearer token added automatically

// 3. Logout - token is cleared
await AuthService.logout();
```

### Manual Token Handling (if needed)

```dart
// Get current token
final token = await AuthService.getToken();

// Check if logged in
final isLoggedIn = await AuthService.isLoggedIn();

// Clear token
await AuthService.logout();
```

---

## Result Classes

### AuthResult

```dart
class AuthResult {
  final bool success;
  final String message;
}
```

### EmergencyResult

```dart
class EmergencyResult {
  final bool success;
  final String message;
  final String? eventId;
  final bool threatDetected;
  final double? confidenceScore;
  final String? transcription;
}
```

### ContactResult

```dart
class ContactResult {
  final bool success;
  final String message;
  final String? contactId;
}
```

### GetContactsResult

```dart
class GetContactsResult {
  final bool success;
  final String message;
  final List<EmergencyContact> contacts;
}
```

### EmergencyEvent

```dart
class EmergencyEvent {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String status; // active, resolved, cancelled
  final int alertsSent;
  final List<String> contactsNotified;
  final DateTime timestamp;
}
```

---

## Usage in Screens

### Full Example: Home Screen with Emergency

```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEmergencyLoading = false;
  List<EmergencyContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final result = await ContactService.getContacts();
    if (result.success) {
      setState(() => _contacts = result.contacts);
    }
  }

  Future<void> _triggerEmergency() async {
    setState(() => _isEmergencyLoading = true);

    try {
      // Get GPS location
      final position = await Geolocator.getCurrentPosition();

      // Trigger emergency
      final result = await EmergencyService.triggerEmergency(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 ${result.message}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isEmergencyLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Emergency Button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isEmergencyLoading ? null : _triggerEmergency,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.all(32),
              ),
              child: _isEmergencyLoading
                  ? CircularProgressIndicator()
                  : Text('SOS Emergency', textAlign: TextAlign.center),
            ),
          ),
          // Contacts List
          Expanded(
            child: _contacts.isEmpty
                ? Center(child: Text('No contacts added'))
                : ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return ListTile(
                        title: Text(contact.name),
                        subtitle: Text(contact.phone),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

---

## API Endpoints Reference

| Method | Endpoint                        | Authentication | Purpose                    |
| ------ | ------------------------------- | -------------- | -------------------------- |
| POST   | `/auth/register`                | No             | Register new user          |
| POST   | `/auth/login`                   | No             | Login user                 |
| POST   | `/emergency/trigger`            | Yes            | Trigger emergency manually |
| POST   | `/emergency/upload-audio`       | Yes            | Upload and analyze audio   |
| POST   | `/emergency/analyze-text`       | Yes            | Analyze text for threats   |
| GET    | `/emergency/events`             | Yes            | Get all emergency events   |
| GET    | `/emergency/events/:id`         | Yes            | Get specific event         |
| PUT    | `/emergency/events/:id/resolve` | Yes            | Resolve emergency          |
| PUT    | `/emergency/events/:id/cancel`  | Yes            | Cancel emergency           |
| POST   | `/contacts/add`                 | Yes            | Add emergency contact      |
| GET    | `/contacts`                     | Yes            | Get all contacts           |
| PUT    | `/contacts/:id`                 | Yes            | Update contact             |
| DELETE | `/contacts/:id`                 | Yes            | Delete contact             |

---

## Configuration

Update the base URL in `lib/config/api_url.dart`:

```dart
class ApiUrl {
  // Development
  static const String baseUrl = 'http://localhost:5000/api';

  // Or Production (when deployed)
  // static const String baseUrl = 'https://api.silentshield.com/api';

  // ... rest of endpoints
}
```

---

## Best Practices

### 1. Always Check Success Status

```dart
final result = await AuthService.login(...);
if (result.success) {
  // Handle success
} else {
  // Handle failure
}
```

### 2. Show User Feedback

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(result.message)),
);
```

### 3. Handle Network Errors

```dart
try {
  final result = await ContactService.addContact(...);
  // Use result
} catch (e) {
  print('Network error: $e');
}
```

### 4. Use Loading States

```dart
setState(() => _isLoading = true);
try {
  final result = await EmergencyService.triggerEmergency(...);
} finally {
  setState(() => _isLoading = false);
}
```

### 5. Check Authentication

```dart
final isLoggedIn = await AuthService.isLoggedIn();
if (!isLoggedIn) {
  // Redirect to login
  Navigator.of(context).pushReplacementNamed('/login');
}
```

---

## Troubleshooting

### "Authentication token not found"

- Make sure user is logged in
- Check that `AuthService.login()` was called successfully

### "Failed to parse response"

- Verify backend is returning valid JSON
- Check network connectivity

### "Request timeout"

- Server might be slow
- Increase timeout in `ApiService` if needed (currently 30s)

### "401 Unauthorized"

- Token expired - user needs to login again
- Implement token refresh logic if needed

### "Network error"

- No internet connection
- Backend API is unreachable

---

## See Also

- [ApiService Source](./services/api_service.dart)
- [AuthService Source](./services/auth_service.dart)
- [EmergencyService Source](./services/emergency_service.dart)
- [ContactService Source](./services/contact_service.dart)
- [Examples](./examples/api_service_examples.dart)
