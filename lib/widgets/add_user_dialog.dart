import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class AddUserDialog extends StatefulWidget {
  final VoidCallback? onUserAdded;

  const AddUserDialog({
    super.key,
    this.onUserAdded,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  // Brand palette (greens only)
  static const Color deepGreen = Color(0xFF0B5D3B);  // Premium deep green
  static const Color midGreen = Color(0xFF2E7D32);   // Medium green
  static const Color lightGreenFill = Color(0xFFE8F5E9); // Very light green fill
  static const Color borderGreen = Color(0xFF66BB6A); // For borders/focus

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check if user already exists
      final existingUser = await DatabaseHelper.instance.getUserByEmail(_emailController.text.trim());
      if (existingUser != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User with this email already exists'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Create new user
      final newUser = User(
        email: _emailController.text.trim(),
        passwordHash: _passwordController.text, // Will be hashed automatically
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: _selectedRole,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userId = await DatabaseHelper.instance.createUser(newUser);

      if (mounted) {
        if (userId > 0) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${newUser.fullName} created successfully'),
              backgroundColor: deepGreen,
            ),
          );
          widget.onUserAdded?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: deepGreen),
      hintStyle: TextStyle(color: deepGreen.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: deepGreen),
      filled: true,
      fillColor: lightGreenFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGreen, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: midGreen, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add New User',
        style: TextStyle(
          color: deepGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: _inputDecoration(
                  label: 'First Name *',
                  icon: Icons.person,
                  hint: 'Enter first name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'First name must be at least 2 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: _inputDecoration(
                  label: 'Last Name *',
                  icon: Icons.person_outline,
                  hint: 'Enter last name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Last name must be at least 2 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration(
                  label: 'Email *',
                  icon: Icons.email,
                  hint: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Password
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration(
                  label: 'Password *',
                  icon: Icons.lock,
                  hint: 'Enter password',
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: deepGreen,
                    ),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Role Selection
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreenFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderGreen),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Role',
                      style: TextStyle(
                        color: deepGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...UserRole.values.map((role) {
                      return RadioListTile<UserRole>(
                        title: Text(
                          role.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          role.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        value: role,
                        groupValue: _selectedRole,
                        activeColor: deepGreen,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: deepGreen,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create User'),
        ),
      ],
    );
  }
}