import 'package:flutter/material.dart';
import '../services/contact_service.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({Key? key}) : super(key: key);

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<EmergencyContact> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  /// Load contacts from backend
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ContactService.getContacts();

      if (mounted) {
        if (result.success) {
          // Sort contacts by priority (ascending: 1 = highest)
          final sorted = result.contacts
            ..sort((a, b) => a.priority.compareTo(b.priority));

          setState(() {
            _contacts = sorted;
            _isLoading = false;
          });

          print('Contacts loaded successfully: ${_contacts.length} contacts');
        } else {
          setState(() {
            _errorMessage = result.message;
            _isLoading = false;
          });
          print('Failed to load contacts: ${result.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
        print('Exception loading contacts: $e');
      }
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(EmergencyContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
            'Are you sure you want to delete ${contact.name}?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteContact(contact);
    }
  }

  /// Delete contact from backend
  Future<void> _deleteContact(EmergencyContact contact) async {
    try {
      print('Deleting contact: ${contact.id} (${contact.name})');

      final result = await ContactService.deleteContact(contact.id);

      if (mounted) {
        if (result.success) {
          // Remove from list
          setState(() {
            _contacts.removeWhere((c) => c.id == contact.id);
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result.message}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          print('Contact deleted successfully: ${contact.id}');
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );

          print('Failed to delete contact: ${result.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );

        print('Exception deleting contact: $e');
      }
    }
  }

  /// Get priority color (higher priority = warmer color)
  Color _getPriorityColor(int priority) {
    if (priority <= 2) return Colors.red.shade600; // High priority: red
    if (priority <= 5) return Colors.orange.shade600; // Medium: orange
    return Colors.green.shade600; // Low: green
  }

  /// Build a single contact card
  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(contact.priority),
          child: Text(
            contact.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              contact.phone,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (contact.relation.isNotEmpty)
              Text(
                contact.relation,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(contact.priority).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'P${contact.priority}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getPriorityColor(contact.priority),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showDeleteConfirmation(contact),
              child: Icon(
                Icons.delete,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadContacts,
            tooltip: 'Refresh contacts',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadContacts,
        child: _buildBody(),
      ),
    );
  }

  /// Build the main body content
  Widget _buildBody() {
    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load contacts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadContacts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show empty state
    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No emergency contacts yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first emergency contact to get started',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: Navigator.of(context).pop,
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
            ),
          ],
        ),
      );
    }

    // Show contacts list
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_contacts.length} contact${_contacts.length != 1 ? 's' : ''} • Sorted by priority',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return _buildContactCard(contact);
              },
            ),
          ],
        ),
      ),
    );
  }
}
