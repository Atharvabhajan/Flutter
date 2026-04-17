import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
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
    if (priority <= 2) return AppTheme.rose;
    if (priority <= 5) return AppTheme.amber;
    return AppTheme.primaryColor;
  }

  /// Build a single contact card
  Widget _buildContactCard(EmergencyContact contact) {
    final theme = Theme.of(context);
    final color = _getPriorityColor(contact.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text(
              contact.name[0].toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phone,
                  style: theme.textTheme.bodyMedium,
                ),
                if (contact.relation.isNotEmpty)
                  Text(
                    contact.relation,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Priority ${contact.priority}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () => _showDeleteConfirmation(contact),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.hintColor.withValues(alpha: 0.5),
                  size: 22,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Safety Network', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _loadContacts,
            tooltip: 'Refresh network',
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
    final theme = Theme.of(context);
    
    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: theme.colorScheme.error.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 24),
              Text(
                'Sync Failed',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Retry Connection',
                onPressed: _loadContacts,
              ),
            ],
          ),
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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 80,
                color: theme.hintColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text(
                'No Guardians Yet',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Add trusted contacts who should receive alerts when you are in danger.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Add First Guardian',
                onPressed: Navigator.of(context).pop,
              ),
            ],
          ),
        ),
      );
    }

    // Show contacts list
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_contacts.length} Guarded Connections • Priority Sorting',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
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
