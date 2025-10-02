import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Login user
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await DatabaseHelper.instance.authenticateUser(email, password);
      if (user != null) {
        _currentUser = user;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      debugPrint('Login error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    try {
      // Check if user already exists
      final existingUser = await DatabaseHelper.instance.getUserByEmail(email);
      if (existingUser != null) {
        _error = 'User with this email already exists';
        notifyListeners();
        return false;
      }

      // Create new user
      final newUser = User(
        email: email,
        passwordHash: password, // Will be hashed in DatabaseHelper
        firstName: firstName,
        lastName: lastName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userId = await DatabaseHelper.instance.createUser(newUser);
      if (userId > 0) {
        _currentUser = newUser.copyWith(id: userId);
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create user account';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      debugPrint('Registration error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    Map<String, dynamic>? preferences,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      final updatedUser = _currentUser!.copyWith(
        firstName: firstName ?? _currentUser!.firstName,
        lastName: lastName ?? _currentUser!.lastName,
        preferences: preferences ?? _currentUser!.preferences,
        updatedAt: DateTime.now(),
      );

      final success = await DatabaseHelper.instance.updateUser(updatedUser);
      if (success) {
        _currentUser = updatedUser;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Profile update failed: $e';
      debugPrint('Profile update error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      // Verify current password
      final user = await DatabaseHelper.instance.authenticateUser(
        _currentUser!.email,
        currentPassword,
      );

      if (user == null) {
        _error = 'Current password is incorrect';
        notifyListeners();
        return false;
      }

      // Update password
      final success = await DatabaseHelper.instance.updateUserPassword(
        _currentUser!.id!,
        newPassword,
      );

      if (success) {
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Password change failed: $e';
      debugPrint('Password change error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_currentUser?.id == null) return;

    try {
      final user = await DatabaseHelper.instance.getUser(_currentUser!.id!);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get user display name
  String get displayName {
    if (_currentUser == null) return 'Guest';
    return _currentUser!.fullName;
  }

  // Get user initials for avatar
  String get userInitials {
    if (_currentUser == null) return 'G';
    final firstName = _currentUser!.firstName;
    final lastName = _currentUser!.lastName;
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  // Check if user has specific preference
  bool hasPreference(String key) {
    return _currentUser?.preferences?.containsKey(key) ?? false;
  }

  // Get user preference value
  T? getPreference<T>(String key) {
    return _currentUser?.preferences?[key] as T?;
  }

  // Set user preference
  Future<bool> setPreference(String key, dynamic value) async {
    if (_currentUser == null) return false;

    final preferences = Map<String, dynamic>.from(_currentUser!.preferences ?? {});
    preferences[key] = value;

    return await updateProfile(preferences: preferences);
  }

  // Remove user preference
  Future<bool> removePreference(String key) async {
    if (_currentUser == null) return false;

    final preferences = Map<String, dynamic>.from(_currentUser!.preferences ?? {});
    preferences.remove(key);

    return await updateProfile(preferences: preferences);
  }

  // Update user profile with all new fields
  Future<bool> updateUserProfile(User updatedUser) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      final success = await DatabaseHelper.instance.updateUser(updatedUser);
      if (success) {
        _currentUser = updatedUser;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Profile update failed: $e';
      debugPrint('Profile update error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify password for change password functionality
  Future<bool> verifyPassword(String password) async {
    if (_currentUser == null) return false;
    
    try {
      final user = await DatabaseHelper.instance.authenticateUser(
        _currentUser!.email,
        password,
      );
      return user != null;
    } catch (e) {
      debugPrint('Password verification error: $e');
      return false;
    }
  }

  // Update password only
  Future<bool> updatePassword(String newPassword) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      final success = await DatabaseHelper.instance.updateUserPassword(
        _currentUser!.id!,
        newPassword,
      );

      if (success) {
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Password update failed: $e';
      debugPrint('Password update error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}