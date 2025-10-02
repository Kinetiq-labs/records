import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../utils/text_helper.dart';
import '../utils/profile_image_helper.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/supabase_sync_dialog.dart';
import '../providers/update_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _primaryPhoneController;
  late TextEditingController _secondaryPhoneController;
  late TextEditingController _shopNameController;
  late TextEditingController _shopTimingsController;
  late TextEditingController _tehlilPriceController;
  late TextEditingController _ptclNumberController;

  // Time selection state
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  // State variables
  bool _isLoading = false;
  String? _selectedImagePath;
  bool _isEditing = false;

  // Brand palette (matching login screen)
  static const Color deepGreen = Color(0xFF0B5D3B);  // Premium deep green
  static const Color lightGreenFill = Color(0xFFE8F5E9); // Very light green fill
  static const Color borderGreen = Color(0xFF66BB6A); // For borders/focus

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _primaryPhoneController = TextEditingController(text: user?.primaryPhone ?? '');
    _secondaryPhoneController = TextEditingController(text: user?.secondaryPhone ?? '');
    _shopNameController = TextEditingController(text: user?.shopName ?? '');
    _shopTimingsController = TextEditingController(text: user?.shopTimings ?? '');
    _selectedImagePath = user?.profilePicturePath;

    // Initialize tehlil price from user preferences (default 100)
    final tehlilPrice = user?.preferences?['tehlil_price'] ?? 100.0;
    _tehlilPriceController = TextEditingController(text: tehlilPrice.toString());

    // Initialize PTCL number from user preferences
    final ptclNumber = user?.preferences?['ptcl_number'] ?? '';
    _ptclNumberController = TextEditingController(text: ptclNumber.toString());

    // Parse existing shop timings if available
    _parseShopTimings(user?.shopTimings);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    _shopNameController.dispose();
    _shopTimingsController.dispose();
    _tehlilPriceController.dispose();
    _ptclNumberController.dispose();
    super.dispose();
  }

  // Profile picture selection
  Future<void> _selectProfilePicture() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextHelper.title(context, 'select_image'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: Translations.get('camera', languageProvider.currentLanguage),
                  onTap: () => _pickImageFromCamera(),
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: Translations.get('gallery', languageProvider.currentLanguage),
                  onTap: () => _pickImageFromGallery(),
                ),
                if (_selectedImagePath != null)
                  _buildImageSourceOption(
                    icon: Icons.delete_rounded,
                    label: Translations.get('remove_picture', languageProvider.currentLanguage),
                    onTap: () => _removeProfilePicture(),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A3325) : lightGreenFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDarkMode ? const Color(0xFF4A7C59) : borderGreen).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isDarkMode ? const Color(0xFF7FC685) : deepGreen),
            const SizedBox(height: 8),
            BilingualText.bilingual(
              label,
              style: BilingualTextStyles.labelMedium(label, color: isDarkMode ? const Color(0xFF7FC685) : deepGreen),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    // Note: Camera functionality would require additional permissions and packages
    // For now, we'll use file picker as a placeholder
    await _pickImageFromGallery();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null && mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.currentUser?.id;
        
        if (userId != null) {
          // Save the image to app directory
          final savedImagePath = await ProfileImageHelper.saveProfileImage(
            result.files.single.path!,
            userId,
          );
          
          if (savedImagePath != null) {
            // Delete old profile image if exists
            if (_selectedImagePath != null) {
              await ProfileImageHelper.deleteProfileImage(_selectedImagePath);
            }

            if (mounted) {
              setState(() {
                _selectedImagePath = savedImagePath;
              });

              // Update user provider immediately for runtime update
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final updatedUser = userProvider.currentUser!.copyWith(
                profilePicturePath: savedImagePath,
                updatedAt: DateTime.now(),
              );
              await userProvider.updateUserProfile(updatedUser);
            }

            // Clean up old profile images for this user
            await ProfileImageHelper.cleanupOldProfileImages(userId, savedImagePath);
          } else {
            if (mounted) {
              _showSnackBar('Error saving profile image');
            }
          }
        }
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e');
    }
  }

  Future<void> _removeProfilePicture() async {
    // Delete the current profile image file
    if (_selectedImagePath != null) {
      await ProfileImageHelper.deleteProfileImage(_selectedImagePath);
    }
    
    if (mounted) {
      setState(() {
        _selectedImagePath = null;
      });

      // Update user provider immediately for runtime update
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updatedUser = userProvider.currentUser!.copyWith(
        profilePicturePath: null,
        updatedAt: DateTime.now(),
      );
      await userProvider.updateUserProfile(updatedUser);
    }
  }

  // Save changes
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      
      // Prepare updated preferences with tehlil price and PTCL number
      final currentPreferences = Map<String, dynamic>.from(userProvider.currentUser?.preferences ?? {});
      final tehlilPrice = double.tryParse(_tehlilPriceController.text.trim()) ?? 100.0;
      currentPreferences['tehlil_price'] = tehlilPrice;

      // Save PTCL number
      final ptclNumber = _ptclNumberController.text.trim();
      if (ptclNumber.isNotEmpty) {
        currentPreferences['ptcl_number'] = ptclNumber;
      } else {
        currentPreferences.remove('ptcl_number');
      }

      // Create updated user object
      final updatedUser = userProvider.currentUser!.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        primaryPhone: _primaryPhoneController.text.trim().isEmpty
            ? null : _primaryPhoneController.text.trim(),
        secondaryPhone: _secondaryPhoneController.text.trim().isEmpty
            ? null : _secondaryPhoneController.text.trim(),
        shopName: _shopNameController.text.trim().isEmpty
            ? null : _shopNameController.text.trim(),
        shopTimings: _formatShopTimings(),
        profilePicturePath: _selectedImagePath,
        preferences: currentPreferences,
        updatedAt: DateTime.now(),
      );

      // Update user through provider
      await userProvider.updateUserProfile(updatedUser);

      setState(() {
        _isEditing = false;
      });

      _showSnackBar(Translations.get('profile_updated', languageProvider.currentLanguage));
    } catch (e) {
      _showSnackBar('Error updating profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Change password dialog
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: deepGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: DashboardAppBar(
        title: Translations.get('user_settings', languageProvider.currentLanguage),
        showHomeButton: true,
        onHomePressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildPersonalDetailsSection(),
              const SizedBox(height: 24),
              _buildBusinessDetailsSection(),
              const SizedBox(height: 24),
              _buildSyncSection(),
              const SizedBox(height: 24),
              _buildUpdateSection(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final user = Provider.of<UserProvider>(context).currentUser;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextHelper.heading(context, 'profile_information'),
            const SizedBox(height: 20),
            
            // Profile Picture
            Center(
              child: LargeProfileAvatar(
                onTap: _isEditing ? _selectProfilePicture : null,
                showEditIcon: _isEditing,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User Name
            BilingualText.bilingual(
              user?.fullName ?? 'User',
              style: BilingualTextStyles.headlineLarge(user?.fullName ?? 'User'),
            ),
            
            // Email
            BilingualText.bilingual(
              user?.email ?? '',
              style: BilingualTextStyles.bodyMedium(user?.email ?? '', color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPersonalDetailsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextHelper.title(context, 'personal_details'),
                if (!_isEditing)
                  IconButton(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: Icon(Icons.edit_rounded, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF7FC685) : deepGreen),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    labelKey: 'first_name',
                    enabled: _isEditing,
                    validator: (value) => _validateRequired(value, 'first_name'),
                    prefixIcon: Icons.person_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    labelKey: 'last_name',
                    enabled: _isEditing,
                    validator: (value) => _validateRequired(value, 'last_name'),
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _emailController,
              labelKey: 'email_address',
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => _validateEmail(value),
              prefixIcon: Icons.email_rounded,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _primaryPhoneController,
                    labelKey: 'primary_phone',
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    optional: true,
                    prefixIcon: Icons.phone_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _secondaryPhoneController,
                    labelKey: 'secondary_phone',
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    optional: true,
                    prefixIcon: Icons.phone_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDetailsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextHelper.title(context, 'business_details'),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _shopNameController,
              labelKey: 'shop_name',
              enabled: _isEditing,
              optional: true,
              prefixIcon: Icons.store_rounded,
            ),
            
            const SizedBox(height: 16),
            
            _isEditing ? _buildShopTimingSelector() : _buildShopTimingDisplay(),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _tehlilPriceController,
              labelKey: 'tehlil_price',
              enabled: _isEditing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              optional: true,
              prefixIcon: Icons.price_change_rounded,
              validator: (value) => _validatePrice(value),
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _ptclNumberController,
              labelKey: 'ptcl_number',
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              optional: true,
              prefixIcon: Icons.phone_rounded,
              validator: (value) => _validatePTCLNumber(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isEditing) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : TextHelper.label(context, 'save_changes'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isEditing = false;
                      _initializeControllers(); // Reset to original values
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: deepGreen,
                    side: const BorderSide(color: deepGreen),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: TextHelper.label(context, 'cancel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock_rounded, color: deepGreen),
            label: TextHelper.label(context, 'change_password'),
            style: OutlinedButton.styleFrom(
              foregroundColor: deepGreen,
              side: const BorderSide(color: deepGreen),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelKey,
    bool enabled = true,
    bool optional = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelText = Translations.get(labelKey, languageProvider.currentLanguage);
    final optionalText = optional ? ' (${Translations.get('optional', languageProvider.currentLanguage)})' : '';
    final placeholderText = Translations.get('${labelKey}_placeholder', languageProvider.currentLanguage);
    // Create a ValueNotifier to track text changes for dynamic font switching
    final textNotifier = ValueNotifier<String>(controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the field
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: labelText,
                  style: BilingualTextStyles.labelLarge(
                    labelText,
                    color: isDarkMode ? const Color(0xFFE6E1E5) : deepGreen,
                  ),
                ),
                if (!optional)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (optional)
                  TextSpan(
                    text: optionalText,
                    style: BilingualTextStyles.labelSmall(
                      optionalText,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Input field
        ValueListenableBuilder<String>(
          valueListenable: textNotifier,
          builder: (context, currentText, child) {
            return TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              maxLines: maxLines,
              validator: validator,
              onChanged: (value) {
                textNotifier.value = value;
              },
              style: BilingualTextStyles.getTextStyle(
                text: currentText.isEmpty ? 'sample' : currentText,
                color: isDarkMode ? const Color(0xFFE6E1E5) : deepGreen,
                fontWeight: FontWeight.w600,
              ),
          decoration: InputDecoration(
            hintText: placeholderText.isNotEmpty ? placeholderText : 'Enter ${labelText.toLowerCase()}',
            hintStyle: BilingualTextStyles.bodyMedium(
              placeholderText.isNotEmpty ? placeholderText : 'Enter ${labelText.toLowerCase()}',
              color: Colors.grey[500],
            ),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: isDarkMode ? const Color(0xFF7FC685) : deepGreen) : null,
            filled: true,
            fillColor: enabled ? (isDarkMode ? const Color(0xFF1A3325) : lightGreenFill) : (isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100]),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDarkMode ? const Color(0xFF4A7C59) : borderGreen, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDarkMode ? const Color(0xFF7FC685) : deepGreen, width: 2.0),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
            );
          },
        ),
      ],
    );
  }

  String? _validateRequired(String? value, String fieldKey) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (value == null || value.trim().isEmpty) {
      return Translations.get('required_field', languageProvider.currentLanguage);
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (value == null || value.trim().isEmpty) {
      return Translations.get('required_field', languageProvider.currentLanguage);
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return Translations.get('invalid_email', languageProvider.currentLanguage);
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    // Allow empty value since it's optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final price = double.tryParse(value.trim());
    if (price == null || price < 0) {
      return Translations.get('invalid_amount', languageProvider.currentLanguage);
    }
    return null;
  }

  String? _validatePTCLNumber(String? value) {
    // Allow empty value since it's optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final ptclNumber = value.trim();

    // Remove spaces, hyphens, and parentheses for validation
    final cleanNumber = ptclNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // PTCL landline format validation
    // Format: Area code (2-5 digits) + Local number (6-8 digits)
    // Total length typically 8-11 digits
    // Common patterns: 0XX-XXXXXXX, 0XXX-XXXXXX, 0XXXX-XXXXX

    // Check if it contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanNumber)) {
      return 'PTCL number should contain only digits, spaces, hyphens, or parentheses';
    }

    // Check length (8-11 digits)
    if (cleanNumber.length < 8 || cleanNumber.length > 11) {
      return 'PTCL number should be 8-11 digits long';
    }

    // Check if it starts with 0 (area code prefix)
    if (!cleanNumber.startsWith('0')) {
      return 'PTCL number should start with 0 (area code)';
    }

    // Additional format validation for common Pakistani area codes
    // Major cities: 021 (Karachi), 042 (Lahore), 051 (Islamabad), etc.
    final areaCodePatterns = [
      RegExp(r'^0[2-9][1-9]\d{6,8}$'), // 3-digit area codes: 0XX-XXXXXXX (6-8 digits)
      RegExp(r'^0[2-9]\d{2}\d{5,7}$'), // 4-digit area codes: 0XXX-XXXXX (5-7 digits)
      RegExp(r'^0[2-9]\d{3}\d{4,6}$'), // 5-digit area codes: 0XXXX-XXXX (4-6 digits)
    ];

    bool isValidFormat = areaCodePatterns.any((pattern) => pattern.hasMatch(cleanNumber));

    if (!isValidFormat) {
      return 'Invalid PTCL number format. Use format like: 042-12345678';
    }

    return null;
  }

  void _parseShopTimings(String? timings) {
    if (timings == null || timings.isEmpty) return;

    // Parse format like "9:00 AM - 6:00 PM"
    final parts = timings.split(' - ');
    if (parts.length == 2) {
      _openTime = _parseTimeString(parts[0]);
      _closeTime = _parseTimeString(parts[1]);
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final cleanTime = timeStr.trim();
      // Support both English (AM/PM) and Urdu (صبح/شام) period indicators for parsing
      final isAM = cleanTime.toLowerCase().contains('am') || cleanTime.contains('صبح');
      final isPM = cleanTime.toLowerCase().contains('pm') || cleanTime.contains('شام');

      final timeOnly = cleanTime
          .replaceAll(RegExp(r'[ap]m', caseSensitive: false), '')
          .replaceAll('صبح', '')
          .replaceAll('شام', '')
          .trim();
      final parts = timeOnly.split(':');

      if (parts.length == 2) {
        int hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        if (isPM && hour != 12) {
          hour += 12;
        } else if (isAM && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // If parsing fails, return null
    }
    return null;
  }

  String? _formatShopTimings() {
    if (_openTime == null || _closeTime == null) {
      return _shopTimingsController.text.trim().isEmpty ? null : _shopTimingsController.text.trim();
    }

    return '${_formatTimeOfDay(_openTime!)} - ${_formatTimeOfDay(_closeTime!)}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    // Always use English AM/PM regardless of language setting
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;

    return '$displayHour:$minute $period';
  }

  Future<void> _selectTime(bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isOpenTime ? _openTime : _closeTime) ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: deepGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: deepGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }

        // Update the shop timings controller with formatted time
        if (_openTime != null && _closeTime != null) {
          _shopTimingsController.text = _formatShopTimings() ?? '';
        }
      });
    }
  }

  Widget _buildShopTimingDisplay() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: BilingualText.bilingual(
            Translations.get('shop_timings', languageProvider.currentLanguage),
            style: BilingualTextStyles.labelLarge(
              Translations.get('shop_timings', languageProvider.currentLanguage),
              color: isDarkMode ? const Color(0xFFE6E1E5) : deepGreen,
            ),
          ),
        ),
        // Time display containers
        Row(
          children: [
            Expanded(
              child: _buildTimeDisplay(
                label: Translations.get('open_time', languageProvider.currentLanguage),
                time: _openTime,
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeDisplay(
                label: Translations.get('close_time', languageProvider.currentLanguage),
                time: _closeTime,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeDisplay({
    required String label,
    required TimeOfDay? time,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BilingualText.bilingual(
            label,
            style: BilingualTextStyles.bodySmall(
              label,
              color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BilingualText.bilingual(
                time != null ? _formatTimeOfDay(time) : '--:-- --',
                style: BilingualTextStyles.titleMedium(
                  time != null ? _formatTimeOfDay(time) : '--:-- --',
                  color: isDarkMode ? const Color(0xFFE6E1E5) : deepGreen,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Icon(
                Icons.access_time_rounded,
                color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopTimingSelector() {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BilingualText.bilingual(
          Translations.get('shop_timings', languageProvider.currentLanguage),
          style: BilingualTextStyles.titleMedium(
            Translations.get('shop_timings', languageProvider.currentLanguage),
            color: deepGreen,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimeSelector(
                label: Translations.get('open_time', languageProvider.currentLanguage),
                time: _openTime,
                onTap: () => _selectTime(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeSelector(
                label: Translations.get('close_time', languageProvider.currentLanguage),
                time: _closeTime,
                onTap: () => _selectTime(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A3325) : lightGreenFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4A7C59) : borderGreen, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText.bilingual(
              label,
              style: BilingualTextStyles.bodySmall(
                label,
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF7FC685) : deepGreen,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BilingualText.bilingual(
                  time != null ? _formatTimeOfDay(time) : '--:-- --',
                  style: BilingualTextStyles.titleMedium(
                    time != null ? _formatTimeOfDay(time) : '--:-- --',
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF7FC685) : deepGreen,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Icon(
                  Icons.access_time_rounded,
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF7FC685) : deepGreen,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sync_alt,
                  color: deepGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Data Sync & Backup',
                  style: BilingualTextStyles.titleLarge(
                    'Data Sync & Backup',
                    color: deepGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SyncStatusWidget(
              showLabel: true,
              showProgress: true,
              onConfigurePressed: () {
                _showSyncSettingsDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncSettingsDialog() {
    // Show Supabase sync dialog as popup
    showDialog(
      context: context,
      builder: (context) => const SupabaseSyncDialog(),
    );
  }

  Widget _buildUpdateSection() {
    return Consumer<UpdateProvider>(
      builder: (context, updateProvider, child) {
        final languageProvider = Provider.of<LanguageProvider>(context);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.system_update,
                      color: deepGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'App Updates',
                      style: BilingualTextStyles.titleLarge(
                        'App Updates',
                        color: deepGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current version display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Version',
                              style: BilingualTextStyles.bodySmall(
                                'Current Version',
                                color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
                              ).copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              updateProvider.currentVersion ?? '1.0.0',
                              style: BilingualTextStyles.titleMedium(
                                updateProvider.currentVersion ?? '1.0.0',
                                color: isDarkMode ? const Color(0xFFE6E1E5) : deepGreen,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      _buildUpdateStatusIcon(updateProvider, isDarkMode),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Update status and actions
                if (updateProvider.hasUpdate) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.new_releases,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Update Available: ${updateProvider.latestVersion}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (updateProvider.releaseNotes?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            updateProvider.releaseNotes!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (updateProvider.status == UpdateStatus.upToDate) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'You have the latest version',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: updateProvider.isWorking ? null : () {
                          updateProvider.forceCheckForUpdates();
                        },
                        icon: updateProvider.status == UpdateStatus.checking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(updateProvider.status == UpdateStatus.checking
                            ? 'Checking...'
                            : 'Check for Updates'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: deepGreen,
                          side: const BorderSide(color: deepGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (updateProvider.hasUpdate) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: updateProvider.isWorking ? null : () {
                            updateProvider.downloadAndInstallUpdate();
                          },
                          icon: updateProvider.status == UpdateStatus.downloading ||
                                  updateProvider.status == UpdateStatus.installing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: Text(_getUpdateButtonText(updateProvider.status)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: deepGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Download progress
                if (updateProvider.status == UpdateStatus.downloading) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Download Progress'),
                          Text('${(updateProvider.downloadProgress * 100).toInt()}%'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: updateProvider.downloadProgress,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],

                // Error display
                if (updateProvider.status == UpdateStatus.error && updateProvider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            updateProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          onPressed: () => updateProvider.clearError(),
                          icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpdateStatusIcon(UpdateProvider updateProvider, bool isDarkMode) {
    switch (updateProvider.status) {
      case UpdateStatus.updateAvailable:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notification_important,
            color: Colors.orange,
            size: 20,
          ),
        );
      case UpdateStatus.upToDate:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
        );
      case UpdateStatus.checking:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case UpdateStatus.error:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            color: Colors.red,
            size: 20,
          ),
        );
      default:
        return Icon(
          Icons.info_outline,
          color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
          size: 20,
        );
    }
  }

  String _getUpdateButtonText(UpdateStatus status) {
    switch (status) {
      case UpdateStatus.downloading:
        return 'Downloading...';
      case UpdateStatus.installing:
        return 'Installing...';
      default:
        return 'Update Now';
    }
  }
}

// Change Password Dialog
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  static const Color deepGreen = Color(0xFF0B5D3B);
  static const Color lightGreenFill = Color(0xFFE8F5E9);
  static const Color borderGreen = Color(0xFF66BB6A);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      
      // Verify current password
      final isCurrentPasswordValid = await userProvider.verifyPassword(_currentPasswordController.text);
      
      if (!isCurrentPasswordValid) {
        _showSnackBar(Translations.get('incorrect_current_password', languageProvider.currentLanguage));
        return;
      }

      // Update password
      await userProvider.updatePassword(_newPasswordController.text);
      
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(Translations.get('password_updated', languageProvider.currentLanguage));
      }
    } catch (e) {
      _showSnackBar('Error changing password: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: deepGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextHelper.title(context, 'change_password'),
              const SizedBox(height: 20),
              
              _buildPasswordField(
                controller: _currentPasswordController,
                labelKey: 'current_password',
                obscureText: _obscureCurrentPassword,
                onToggleVisibility: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                validator: (value) => _validateRequired(value, 'current_password'),
              ),
              
              const SizedBox(height: 16),
              
              _buildPasswordField(
                controller: _newPasswordController,
                labelKey: 'new_password',
                obscureText: _obscureNewPassword,
                onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                validator: (value) => _validateNewPassword(value),
              ),
              
              const SizedBox(height: 16),
              
              _buildPasswordField(
                controller: _confirmPasswordController,
                labelKey: 'confirm_new_password',
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                validator: (value) => _validateConfirmPassword(value),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: deepGreen,
                        side: const BorderSide(color: deepGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: TextHelper.label(context, 'cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : TextHelper.label(context, 'save_changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelKey,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelText = Translations.get(labelKey, languageProvider.currentLanguage);
    // Create a ValueNotifier to track text changes for dynamic font switching
    final textNotifier = ValueNotifier<String>(controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the field
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: labelText,
                  style: BilingualTextStyles.labelLarge(
                    labelText,
                    color: isDarkMode ? const Color(0xFFE6E1E5) : deepGreen,
                  ),
                ),
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Password field
        ValueListenableBuilder<String>(
          valueListenable: textNotifier,
          builder: (context, currentText, child) {
            return TextFormField(
              controller: controller,
              obscureText: obscureText,
              validator: validator,
              onChanged: (value) {
                textNotifier.value = value;
              },
              style: BilingualTextStyles.getTextStyle(
                text: currentText.isEmpty ? 'sample' : currentText,
                color: isDarkMode ? const Color(0xFFE6E1E5) : deepGreen,
                fontWeight: FontWeight.w600,
              ),
          decoration: InputDecoration(
            hintText: 'Enter ${labelText.toLowerCase()}',
            hintStyle: BilingualTextStyles.bodyMedium(
              'Enter ${labelText.toLowerCase()}',
              color: Colors.grey[500],
            ),
            prefixIcon: Icon(Icons.lock_rounded, color: isDarkMode ? const Color(0xFF7FC685) : deepGreen),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1A3325) : lightGreenFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDarkMode ? const Color(0xFF4A7C59) : borderGreen, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDarkMode ? const Color(0xFF7FC685) : deepGreen, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
            );
          },
        ),
      ],
    );
  }

  String? _validateRequired(String? value, String fieldKey) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (value == null || value.isEmpty) {
      return Translations.get('required_field', languageProvider.currentLanguage);
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (value == null || value.isEmpty) {
      return Translations.get('required_field', languageProvider.currentLanguage);
    }
    if (value.length < 6) {
      return Translations.get('password_too_short', languageProvider.currentLanguage);
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (value == null || value.isEmpty) {
      return Translations.get('required_field', languageProvider.currentLanguage);
    }
    if (value != _newPasswordController.text) {
      return Translations.get('passwords_do_not_match', languageProvider.currentLanguage);
    }
    return null;
  }

}