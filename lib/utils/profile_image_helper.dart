import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfileImageHelper {
  static const String _profileImageDir = 'profile_images';
  
  /// Save profile image to app directory
  static Future<String?> saveProfileImage(String sourcePath, int userId) async {
    try {
      // Get app documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory(path.join(appDocDir.path, _profileImageDir));
      
      // Create directory if it doesn't exist
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }
      
      // Generate unique filename based on userId and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(sourcePath);
      final fileName = 'profile_${userId}_$timestamp$extension';
      final targetPath = path.join(profileImagesDir.path, fileName);
      
      // Copy source image to app directory
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('Source file does not exist: $sourcePath');
        return null;
      }
      
      final targetFile = await sourceFile.copy(targetPath);
      debugPrint('Profile image saved to: ${targetFile.path}');
      
      return targetFile.path;
    } catch (e) {
      debugPrint('Error saving profile image: $e');
      return null;
    }
  }
  
  /// Load profile image from app directory
  static Future<File?> loadProfileImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      } else {
        debugPrint('Profile image file not found: $imagePath');
        return null;
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
      return null;
    }
  }
  
  /// Delete old profile image
  static Future<bool> deleteProfileImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return true;
    }
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted old profile image: $imagePath');
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
      return false;
    }
  }
  
  /// Clean up old profile images for a user (keep only the most recent one)
  static Future<void> cleanupOldProfileImages(int userId, String? currentImagePath) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory(path.join(appDocDir.path, _profileImageDir));
      
      if (!await profileImagesDir.exists()) {
        return;
      }
      
      // List all files in profile images directory
      final files = await profileImagesDir.list().toList();
      
      // Filter files for this user
      final userFiles = files.whereType<File>().where((file) {
        final fileName = path.basename(file.path);
        return fileName.startsWith('profile_${userId}_');
      }).toList();
      
      // Delete all user profile images except the current one
      for (final file in userFiles) {
        if (currentImagePath == null || file.path != currentImagePath) {
          try {
            await file.delete();
            debugPrint('Cleaned up old profile image: ${file.path}');
          } catch (e) {
            debugPrint('Error deleting old profile image: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old profile images: $e');
    }
  }
  
  /// Get profile images directory path
  static Future<String> getProfileImagesDirectoryPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, _profileImageDir);
  }
  
  /// Check if profile image exists and is valid
  static Future<bool> isValidProfileImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }
    
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return false;
      }
      
      // Check if file size is reasonable (not empty, not too large)
      final stat = await file.stat();
      if (stat.size == 0 || stat.size > 10 * 1024 * 1024) { // Max 10MB
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error validating profile image: $e');
      return false;
    }
  }
  
  /// Get file size in bytes
  static Future<int> getImageFileSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
    } catch (e) {
      debugPrint('Error getting image file size: $e');
    }
    return 0;
  }
  
  /// Create backup of profile image
  static Future<String?> createImageBackup(String imagePath, int userId) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDocDir.path, 'profile_backups'));
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        return null;
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imagePath);
      final backupFileName = 'backup_profile_${userId}_$timestamp$extension';
      final backupPath = path.join(backupDir.path, backupFileName);
      
      final backupFile = await sourceFile.copy(backupPath);
      debugPrint('Profile image backup created: ${backupFile.path}');
      
      return backupFile.path;
    } catch (e) {
      debugPrint('Error creating image backup: $e');
      return null;
    }
  }
}