// ============================================================================
// COMPLETE IMPLEMENTATION EXAMPLE: HOME SCREEN WITH API INTEGRATION
// ============================================================================
// This file shows a complete, production-ready implementation of the Home
// Screen that uses ApiService, AuthService, EmergencyService, and ContactService

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/emergency_service.dart';
import '../services/contact_service.dart';
import '../config/app_theme.dart';

class HomeScreenComplete extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreenComplete({required this.onLogout});

  @override
  State<HomeScreenComplete> createState() => _HomeScreenCompleteState();
}

class _HomeScreenCompleteState extends State<HomeScreenComplete> {
  // Loading states
  bool _isEmergencyLoading = false;
  bool _isContactsLoading = false;

  // Data
  List<EmergencyContact> _contacts = [];
  String? _userName;

  // Page state
  int _selectedTab = 0; // 0: Home, 1: Contacts, 2: History

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadContacts();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // USER DATA LOADING
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUserData();
      if (userData != null) {
        setState(() => _userName = userData['name'] ?? 'User');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EMERGENCY FUNCTIONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Main emergency trigger function
  Future<void> _triggerEmergency() async {
    setState(() => _isEmergencyLoading = true);

    try {
      // Get current GPS location
      final position = await _getCurrentLocation();
      if (position == null) {
        _showError('Could not get GPS location');
        return;
      }

      // Trigger emergency with location
      final result = await EmergencyService.triggerEmergency(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        if (result.success) {
          _showSuccess(
            '🚨 EMERGENCY TRIGGERED!',
            'Event ID: ${result.eventId}\n${result.message}',
            Colors.red,
          );
        } else {
          _showError(result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Emergency trigger failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isEmergencyLoading = false);
      }
    }
  }

  /// Get current GPS location
  Future<Position?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          _showError('Location permission denied');
          return null;
        }
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Location error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CONTACT FUNCTIONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Load all contacts
  Future<void> _loadContacts() async {
    setState(() => _isContactsLoading = true);

    try {
      final result = await ContactService.getContacts();
      if (result.success) {
        setState(() => _contacts = result.contacts);
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('Failed to load contacts: $e');
    } finally {
      setState(() => _isContactsLoading = false);
    }
  }

  /// Add a new contact
  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRelation = 'Family';
    int selectedPriority = 1;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Contact Name',
                    hintText: 'e.g., Mom, Best Friend',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g., 1234567890',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email (optional)',
                    hintText: 'e.g., mom@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedRelation,
                  isExpanded: true,
                  items: ['Family', 'Friend', 'Doctor', 'Other']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedRelation = value!);
                  },
                ),
                SizedBox(height: 12),
                Text('Priority: $selectedPriority'),
                Slider(
                  value: selectedPriority.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setDialogState(() => selectedPriority = value.toInt());
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  _showError('Name and phone are required');
                  return;
                }

                Navigator.pop(context);

                final result = await ContactService.addContact(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  relation: selectedRelation,
                  priority: selectedPriority,
                );

                if (result.success) {
                  _showSuccess(
                    '✓ Contact Added',
                    result.message,
                    Colors.green,
                  );
                  _loadContacts();
                } else {
                  _showError(result.message);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
  }

  /// Delete a contact
  Future<void> _deleteContact(String contactId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Contact'),
        content: Text('Delete $name from emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ContactService.deleteContact(contactId);
      if (result.success) {
        _showSuccess('✓ Contact Deleted', result.message, Colors.green);
        _loadContacts();
      } else {
        _showError(result.message);
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HISTORY FUNCTIONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Load emergency history
  Future<GetEventsResult> _loadEmergencyHistory() async {
    try {
      return await EmergencyService.getEmergencyEvents();
    } catch (e) {
      return GetEventsResult(
        success: false,
        message: e.toString(),
        events: [],
      );
    }
  }

  /// Resolve an emergency event
  Future<void> _resolveEmergency(String eventId) async {
    final result = await EmergencyService.resolveEmergency(eventId);
    if (result.success) {
      _showSuccess('✓ Emergency Resolved', result.message, Colors.green);
      setState(() {}); // Trigger rebuild to update history
    } else {
      _showError(result.message);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LOGOUT FUNCTION
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      widget.onLogout();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ──────────────────────────────────────────────────────────────────────────

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String title, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UI BUILDERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Home Tab - Main Dashboard
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Welcome, $_userName!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Stay Safe. Always Connected.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Emergency Button
          ElevatedButton(
            onPressed: _isEmergencyLoading ? null : _triggerEmergency,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.all(40),
              shape: CircleBorder(),
            ),
            child: _isEmergencyLoading
                ? SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_rounded,
                          size: 48, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'EMERGENCY',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: 24),

          // Emergency Contacts Summary
          Card(
            child: ListTile(
              leading: Icon(Icons.people, color: AppTheme.primaryColor),
              title: Text('Emergency Contacts'),
              subtitle: Text('${_contacts.length} contacts saved'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
          SizedBox(height: 16),

          // Emergency History Summary
          Card(
            child: ListTile(
              leading: Icon(Icons.history, color: AppTheme.primaryColor),
              title: Text('Emergency History'),
              subtitle: Text('View past emergencies'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () => setState(() => _selectedTab = 2),
            ),
          ),
          SizedBox(height: 16),

          // Settings Card
          Card(
            child: ListTile(
              leading: Icon(Icons.settings, color: AppTheme.primaryColor),
              title: Text('Logout'),
              trailing: Icon(Icons.arrow_forward),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }

  /// Contacts Tab
  Widget _buildContactsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _isContactsLoading ? null : _loadContacts,
              ),
            ],
          ),
        ),
        if (_isContactsLoading)
          Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_contacts.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No contacts added yet'),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddContactDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add Contact'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(contact.name),
                    subtitle: Text('${contact.relation} • ${contact.phone}'),
                    trailing: GestureDetector(
                      onLongPress: () =>
                          _deleteContact(contact.id, contact.name),
                      child: Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddContactDialog,
              icon: Icon(Icons.add),
              label: Text('Add Contact'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// History Tab
  Widget _buildHistoryTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Emergency History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<GetEventsResult>(
            future: _loadEmergencyHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.success) {
                return Center(child: Text('Failed to load history'));
              }

              final events = snapshot.data!.events;
              if (events.isEmpty) {
                return Center(child: Text('No emergency events'));
              }

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final statusColor = event.status == 'active'
                      ? Colors.red
                      : event.status == 'resolved'
                          ? Colors.green
                          : Colors.grey;

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: statusColor.withOpacity(0.1),
                    child: ListTile(
                      leading: Icon(Icons.warning_rounded, color: statusColor),
                      title: Text('Emergency Alert'),
                      subtitle: Text(
                        'Status: ${event.status}\n'
                        'Contacts Notified: ${event.contactsNotified.length}\n'
                        'Time: ${event.timestamp.toString().split('.')[0]}',
                      ),
                      trailing: event.status == 'active'
                          ? ElevatedButton(
                              onPressed: () => _resolveEmergency(event.id),
                              child: Text('Resolve'),
                            )
                          : Text(event.status),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MAIN BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Silent Emergency Shield'),
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildHomeTab(),
          _buildContactsTab(),
          _buildHistoryTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
