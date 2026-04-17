import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Add Guardian', style: theme.textTheme.titleLarge),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header text
                Text(
                  'Add a trusted contact who will receive alerts during emergencies.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // ─── Name Field ───────────────────────────────────────────────
                TextFormField(
                  controller: _nameController,
                  readOnly: _isLoading,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Johnathan Doe',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),

                // ─── Phone Field ──────────────────────────────────────────────
                TextFormField(
                  controller: _phoneController,
                  readOnly: _isLoading,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '10-digit number',
                    prefixIcon: Icon(Icons.phone_rounded),
                    maxLength: 10,
                    counterText: '', // Hide default counter
                  ),
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),

                // ─── Relation Dropdown ────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _selectedRelation,
                  dropdownColor: theme.cardTheme.color,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Relation',
                    prefixIcon: Icon(Icons.people_rounded),
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
                const SizedBox(height: 20),

                // ─── Email Field (Optional) ───────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  readOnly: _isLoading,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(Icons.email_rounded),
                  ),
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),

                // ─── Telegram Chat ID Field (Optional) ────────────────────────
                TextFormField(
                  controller: _telegramController,
                  readOnly: _isLoading,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Telegram Chat ID (Optional)',
                    hintText: 'Secure alert ID',
                    prefixIcon: Icon(Icons.telegram_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),

                // ─── Priority Dropdown ────────────────────────────────────────
                DropdownButtonFormField<int>(
                  value: _selectedPriority,
                  dropdownColor: theme.cardTheme.color,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Safety Priority',
                    hintText: '1 = Highest Priority',
                    prefixIcon: Icon(Icons.priority_high_rounded),
                  ),
                  isExpanded: true,
                  items: _priorityOptions.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text('Priority $priority'),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() => _selectedPriority = value ?? 1);
                        },
                ),
                const SizedBox(height: 48),

                // ─── Submit Button ────────────────────────────────────────────
                CustomButton(
                  label: 'Add Guardian',
                  isLoading: _isLoading,
                  onPressed: _submitForm,
                ),
                const SizedBox(height: 16),

                // ─── Cancel Button ────────────────────────────────────────────
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: theme.hintColor,
                  ),
                  child: const Text('Cancel Request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
