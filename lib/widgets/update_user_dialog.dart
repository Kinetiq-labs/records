import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class UpdateUserDialog extends StatefulWidget {
  final User user;
  final VoidCallback? onUserUpdated;

  const UpdateUserDialog({
    super.key,
    required this.user,
    this.onUserUpdated,
  });

  @override
  State<UpdateUserDialog> createState() => _UpdateUserDialogState();
}

class _UpdateUserDialogState extends State<UpdateUserDialog> {
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
  
  UserRole? _selectedRole;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email;
    _firstNameController.text = widget.user.firstName;
    _lastNameController.text = widget.user.lastName;
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check if email is being changed and if new email already exists
      if (_emailController.text.trim() != widget.user.email) {
        final existingUser = await DatabaseHelper.instance.getUserByEmail(_emailController.text.trim());
        if (existingUser != null && existingUser.id != widget.user.id) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Another user with this email already exists'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update user information
      final updatedUser = widget.user.copyWith(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: _selectedRole,
        updatedAt: DateTime.now(),
      );

      final success = await DatabaseHelper.instance.updateUser(updatedUser);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update user information'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Update password if requested
      if (_changePassword && _passwordController.text.isNotEmpty) {
        final passwordSuccess = await DatabaseHelper.instance.updateUserPassword(
          widget.user.id!,
          _passwordController.text,
        );

        if (!passwordSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User updated but failed to change password'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedUser.fullName} updated successfully'),
            backgroundColor: deepGreen,
          ),
        );
        widget.onUserUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
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
      labelStyle: const TextStyle(
        color: deepGreen,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: deepGreen.withOpacity(0.6),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: deepGreen, size: 22),
      filled: true,
      fillColor: lightGreenFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGreen, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: midGreen, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      errorStyle: const TextStyle(
        fontSize: 13,
        height: 1.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update User',
            style: TextStyle(
              color: deepGreen,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.fullName,
            style: TextStyle(
              color: deepGreen.withOpacity(0.7),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          minWidth: 300,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // First Name
                TextFormField(
                  controller: _firstNameController,
                  style: const TextStyle(
                    color: deepGreen, 
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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
                
                const SizedBox(height: 20),
                
                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  style: const TextStyle(
                    color: deepGreen, 
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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
                
                const SizedBox(height: 20),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: deepGreen, 
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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
                
                const SizedBox(height: 20),
                
                // Password Change Section
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
                      Row(
                        children: [
                          Checkbox(
                            value: _changePassword,
                            activeColor: deepGreen,
                            onChanged: (value) {
                              setState(() {
                                _changePassword = value ?? false;
                                if (!_changePassword) {
                                  _passwordController.clear();
                                }
                              });
                            },
                          ),
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              color: deepGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (_changePassword) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(
                    color: deepGreen, 
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                          decoration: _inputDecoration(
                            label: 'New Password *',
                            icon: Icons.lock,
                            hint: 'Enter new password',
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
                            if (_changePassword) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedRole = role),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedRole == role 
                                    ? deepGreen.withOpacity(0.1) 
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _selectedRole == role 
                                      ? deepGreen 
                                      : borderGreen.withOpacity(0.3),
                                  width: _selectedRole == role ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Radio<UserRole>(
                                    value: role,
                                    groupValue: _selectedRole,
                                    activeColor: deepGreen,
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedRole = value);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          role.displayName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _selectedRole == role 
                                                ? deepGreen 
                                                : Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          role.description,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _selectedRole == role 
                                                ? deepGreen.withOpacity(0.8) 
                                                : Colors.grey[600],
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateUser,
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
              : const Text('Update User'),
        ),
      ],
    );
  }
}