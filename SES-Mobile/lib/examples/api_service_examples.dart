// ============================================================================
// API SERVICE INTEGRATION EXAMPLES
// ============================================================================
// This file demonstrates how to use the ApiService, AuthService,
// EmergencyService, and ContactService in your Flutter app screens.

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/emergency_service.dart';
import '../services/contact_service.dart';

// ============================================================================
// EXAMPLE 1: LOGIN SCREEN WITH API SERVICE
// ============================================================================
class LoginScreenExample extends StatefulWidget {
  @override
  State<LoginScreenExample> createState() => _LoginScreenExampleState();
}

class _LoginScreenExampleState extends State<LoginScreenExample> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.success) {
        // Login successful - navigate to home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ ${result.message}')),
        );
        // Navigate to home screen
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✗ ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(hintText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(hintText: 'Password'),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading ? CircularProgressIndicator() : Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 2: REGISTER SCREEN WITH API SERVICE
// ============================================================================
class RegisterScreenExample extends StatefulWidget {
  @override
  State<RegisterScreenExample> createState() => _RegisterScreenExampleState();
}

class _RegisterScreenExampleState extends State<RegisterScreenExample> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ ${result.message}')),
        );
        // Auto-login or navigate to login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✗ ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Full Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: 'Phone Number'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading ? CircularProgressIndicator() : Text('Register'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 3: TRIGGER EMERGENCY WITH LOCATION
// ============================================================================
class EmergencyScreenExample extends StatefulWidget {
  @override
  State<EmergencyScreenExample> createState() => _EmergencyScreenExampleState();
}

class _EmergencyScreenExampleState extends State<EmergencyScreenExample> {
  bool _isLoading = false;

  Future<void> _triggerEmergency() async {
    setState(() => _isLoading = true);

    try {
      // Simulated GPS coordinates (in production, use geolocator package)
      const latitude = 40.7128;
      const longitude = -74.0060;

      final result = await EmergencyService.triggerEmergency(
        latitude: latitude,
        longitude: longitude,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
        // Show emergency event details
        if (result.eventId != null) {
          print('Emergency Event ID: ${result.eventId}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✗ ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _triggerEmergency,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.all(32),
          ),
          child: _isLoading
              ? CircularProgressIndicator()
              : Text(
                  'SOS\nEmergency',
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 4: TEXT THREAT ANALYSIS
// ============================================================================
class AnalyzeTextScreenExample extends StatefulWidget {
  @override
  State<AnalyzeTextScreenExample> createState() =>
      _AnalyzeTextScreenExampleState();
}

class _AnalyzeTextScreenExampleState extends State<AnalyzeTextScreenExample> {
  final _textController = TextEditingController();
  bool _isLoading = false;
  String? _result;

  Future<void> _analyzeText() async {
    setState(() => _isLoading = true);

    try {
      final result = await EmergencyService.analyzeText(
        text: _textController.text.trim(),
        latitude: 0,
        longitude: 0,
      );

      setState(() {
        if (result.threatDetected) {
          _result =
              '🚨 THREAT DETECTED!\nConfidence: ${(result.confidenceScore ?? 0).toStringAsFixed(2)}%';
        } else {
          _result = '✓ No threat detected';
        }
        _result = '$_result\n\nMessage: ${result.message}';
      });
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Enter text to analyze'),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeText,
              child: _isLoading ? CircularProgressIndicator() : Text('Analyze'),
            ),
            if (_result != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_result!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 5: CONTACT MANAGEMENT - ADD CONTACT
// ============================================================================
class AddContactScreenExample extends StatefulWidget {
  final VoidCallback onContactAdded;

  const AddContactScreenExample({required this.onContactAdded});

  @override
  State<AddContactScreenExample> createState() =>
      _AddContactScreenExampleState();
}

class _AddContactScreenExampleState extends State<AddContactScreenExample> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _relation = 'Family';
  int _priority = 1;
  bool _isLoading = false;

  Future<void> _addContact() async {
    setState(() => _isLoading = true);

    try {
      final result = await ContactService.addContact(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        relation: _relation,
        priority: _priority,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ ${result.message}')),
        );
        widget.onContactAdded();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✗ ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Contact')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Contact Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email (optional)'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _relation,
              isExpanded: true,
              items: ['Family', 'Friend', 'Doctor', 'Other']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (value) => setState(() => _relation = value!),
            ),
            SizedBox(height: 16),
            Slider(
              value: _priority.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: 'Priority: $_priority',
              onChanged: (value) => setState(() => _priority = value.floor()),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addContact,
              child: Text(_isLoading ? 'Adding...' : 'Add Contact'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 6: CONTACT MANAGEMENT - LIST CONTACTS
// ============================================================================
class ContactListScreenExample extends StatefulWidget {
  @override
  State<ContactListScreenExample> createState() =>
      _ContactListScreenExampleState();
}

class _ContactListScreenExampleState extends State<ContactListScreenExample> {
  late Future<GetContactsResult> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    _contactsFuture = ContactService.getContacts();
  }

  Future<void> _deleteContact(String contactId) async {
    final result = await ContactService.deleteContact(contactId);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ ${result.message}')),
      );
      setState(() => _loadContacts());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✗ ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Emergency Contacts')),
      body: FutureBuilder<dynamic>(
        future: _contactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Failed to load contacts'));
          }

          final result = snapshot.data;
          if (result == null || !result.success) {
            return Center(child: Text('Failed to load contacts'));
          }

          final contacts = result.contacts ?? [];
          if (contacts.isEmpty) {
            return Center(child: Text('No contacts added yet'));
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                title: Text(contact.name),
                subtitle: Text('${contact.relation} • ${contact.phone}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteContact(contact.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddContactScreenExample(
                onContactAdded: _loadContacts,
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 7: EMERGENCY EVENT HISTORY
// ============================================================================
class EmergencyHistoryScreenExample extends StatefulWidget {
  @override
  State<EmergencyHistoryScreenExample> createState() =>
      _EmergencyHistoryScreenExampleState();
}

class _EmergencyHistoryScreenExampleState
    extends State<EmergencyHistoryScreenExample> {
  late Future<GetEventsResult> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = EmergencyService.getEmergencyEvents();
  }

  Future<void> _resolveEvent(String eventId) async {
    final result = await EmergencyService.resolveEmergency(eventId);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Emergency resolved')),
      );
      setState(() => _eventsFuture = EmergencyService.getEmergencyEvents());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Emergency History')),
      body: FutureBuilder<dynamic>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Failed to load events'));
          }

          final result = snapshot.data;
          if (result == null || !result.success) {
            return Center(child: Text('Failed to load events'));
          }

          final events = result.events ?? [];
          if (events.isEmpty) {
            return Center(child: Text('No emergency events'));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              return Card(
                child: ListTile(
                  title: Text('Emergency Alert'),
                  subtitle: Text(
                    'Status: ${event.status}\n'
                    'Alerts Sent: ${event.alertsSent}\n'
                    'Time: ${event.timestamp.toString()}',
                  ),
                  trailing: event.status == 'active'
                      ? ElevatedButton(
                          onPressed: () => _resolveEvent(event.id),
                          child: Text('Resolve'),
                        )
                      : Text(event.status),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 8: ERROR HANDLING WITH API SERVICE
// ============================================================================
class ErrorHandlingExample extends StatefulWidget {
  @override
  State<ErrorHandlingExample> createState() => _ErrorHandlingExampleState();
}

class _ErrorHandlingExampleState extends State<ErrorHandlingExample> {
  String _errorMessage = '';

  Future<void> _demonstrateErrorHandling() async {
    try {
      // This will fail due to invalid credentials
      await ApiService.login(
        email: 'nonexistent@example.com',
        password: 'wrongpassword',
      );
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _demonstrateErrorHandling,
              child: Text('Trigger Error'),
            ),
            if (_errorMessage.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.red.withOpacity(0.1),
                child: Text(_errorMessage),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
