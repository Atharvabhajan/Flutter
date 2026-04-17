import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/contact_service.dart';

class AddContactScreen extends StatefulWidget {
  final VoidCallback? onContactAdded;

  const AddContactScreen({
    Key? key,
    this.onContactAdded,
  }) : super(key: key);

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  // Form controller
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _telegramController = TextEditingController();

  // Form state
  String _selectedRelation = 'Other';
  int _selectedPriority = 1;
  bool _isLoading = false;

  final List<String> _relationOptions = ['Family', 'Friend', 'Doctor', 'Other'];
  final List<int> _priorityOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  /// Validate phone number (10 digits exactly)
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  /// Validate name
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.trim().isEmpty) {
      return 'Name cannot be just spaces';
    }
    return null;
  }

  /// Validate email (optional but if provided must be valid)
  String? _validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email';
      }
    }
    return null;
  }

  /// Submit the form
  void _submitForm() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prepare data
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : null;
    final telegramChatId = _telegramController.text.trim().isNotEmpty 
        ? _telegramController.text.trim()
        : null;
    final relation = _selectedRelation;
    final priority = _selectedPriority;

    // Log request
    print('=== Adding Contact ===');
    print('Name: $name');
    print('Phone: $phone');
    print('Email: $email');
    print('Relation: $relation');
    print('Priority: $priority');

    setState(() => _isLoading = true);

    try {
      final result = await ContactService.addContact(
        name: name,
        phone: phone,
        relation: relation,
        email: email,
        telegramChatId: telegramChatId,
        priority: priority,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result.message}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Debug log
          print('Contact added successfully! ID: ${result.contactId}');

          // Callback and navigate back
          widget.onContactAdded?.call();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );

          // Debug log
          print('Failed to add contact: ${result.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Debug log
        print('Exception while adding contact: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Emergency Contact'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header text
                const Text(
                  'Add a new emergency contact to your list',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.hintColor,
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Name Field ───────────────────────────────────────────────
                TextFormField(
                  controller: _nameController,
                  readOnly: _isLoading,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g., John Doe',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // ─── Phone Field ──────────────────────────────────────────────
                TextFormField(
                  controller: _phoneController,
                  readOnly: _isLoading,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '1234567890',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 10,
                ),
                const SizedBox(height: 16),

                // ─── Relation Dropdown ────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _selectedRelation,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    prefixIcon: const Icon(Icons.people),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  isExpanded: true,
                  items: _relationOptions.map((relation) {
                    return DropdownMenuItem(
                      value: relation,
                      child: Text(relation),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() => _selectedRelation = value ?? 'Other');
                        },
                ),
                const SizedBox(height: 16),

                // ─── Email Field (Optional) ───────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  readOnly: _isLoading,
                  decoration: InputDecoration(
                    labelText: 'Email (Optional)',
                    hintText: 'john@example.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // ─── Telegram Chat ID Field (Optional) ────────────────────────
                TextFormField(
                  controller: _telegramController,
                  readOnly: _isLoading,
                  decoration: InputDecoration(
                    labelText: 'Telegram Chat ID (Optional)',
                    hintText: 'e.g., 123456789',
                    prefixIcon: const Icon(Icons.message),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // ─── Priority Dropdown ────────────────────────────────────────
                DropdownButtonFormField<int>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    hintText: 'Select priority (1-10)',
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  isExpanded: true,
                  items: _priorityOptions.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.toString()),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() => _selectedPriority = value ?? 1);
                        },
                ),
                const SizedBox(height: 32),

                // ─── Submit Button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Add Contact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Cancel Button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
