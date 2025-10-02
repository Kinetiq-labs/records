import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/profile_image_helper.dart';

class ProfileAvatar extends StatelessWidget {
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final String? customImagePath;
  final String? customInitials;
  final VoidCallback? onTap;
  final bool showBorder;

  const ProfileAvatar({
    super.key,
    this.size = 40.0,
    this.borderColor,
    this.borderWidth = 2.0,
    this.customImagePath,
    this.customInitials,
    this.onTap,
    this.showBorder = true,
  });

  // Brand colors
  static const Color deepGreen = Color(0xFF0B5D3B);
  static const Color lightGreenFill = Color(0xFFE8F5E9);
  static const Color borderGreen = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        final imagePath = customImagePath ?? user?.profilePicturePath;
        final initials = customInitials ?? _getUserInitials(user);
        final effectiveBorderColor = borderColor ?? borderGreen;

        Widget avatarContent = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lightGreenFill,
            border: showBorder 
                ? Border.all(color: effectiveBorderColor, width: borderWidth)
                : null,
          ),
          child: imagePath != null
              ? FutureBuilder<File?>(
                  future: ProfileImageHelper.loadProfileImage(imagePath),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return ClipOval(
                        child: Image.file(
                          snapshot.data!,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              _buildInitialsAvatar(initials),
                        ),
                      );
                    } else {
                      return _buildInitialsAvatar(initials);
                    }
                  },
                )
              : _buildInitialsAvatar(initials),
        );

        if (onTap != null) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: avatarContent,
          );
        }

        return avatarContent;
      },
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: lightGreenFill,
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.4, // 40% of avatar size
            fontWeight: FontWeight.bold,
            color: deepGreen,
          ),
        ),
      ),
    );
  }

  String _getUserInitials(user) {
    if (user == null) return 'U';
    
    final firstName = user.firstName ?? '';
    final lastName = user.lastName ?? '';
    
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];
    
    return initials.isEmpty ? 'U' : initials;
  }
}

// Specialized profile avatars for different contexts

/// Small profile avatar for app bars and lists
class SmallProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;

  const SmallProfileAvatar({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      size: 36.0,
      borderWidth: 2.0,
      onTap: onTap,
    );
  }
}

/// Medium profile avatar for cards and dialogs
class MediumProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;

  const MediumProfileAvatar({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      size: 60.0,
      borderWidth: 2.5,
      onTap: onTap,
    );
  }
}

/// Large profile avatar for settings and profile pages
class LargeProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showEditIcon;

  const LargeProfileAvatar({
    super.key,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = ProfileAvatar(
      size: 120.0,
      borderWidth: 3.0,
      onTap: onTap,
    );

    if (showEditIcon) {
      return Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: ProfileAvatar.deepGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }
}

/// Compact profile avatar for dense layouts
class CompactProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactProfileAvatar({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      size: 28.0,
      borderWidth: 1.5,
      onTap: onTap,
    );
  }
}

/// Profile avatar with status indicator
class ProfileAvatarWithStatus extends StatelessWidget {
  final double size;
  final bool isOnline;
  final VoidCallback? onTap;

  const ProfileAvatarWithStatus({
    super.key,
    this.size = 40.0,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ProfileAvatar(
          size: size,
          onTap: onTap,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.25,
            height: size * 0.25,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}