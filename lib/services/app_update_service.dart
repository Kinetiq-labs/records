import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  static const String _updateUrlKey = 'update_check_url';
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _delayedUpdateKey = 'delayed_update_until';
  static const String _latestVersionKey = 'latest_version';

  // Configure your update server URL here
  // Set to null to disable automatic update checking during development
  static const String? defaultUpdateUrl = null; // 'https://your-server.com/api/app-version';

  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('Error getting current version: $e');
      // For desktop platforms, read version from pubspec.yaml or use fallback
      return '1.0.0+1'; // fallback version matching pubspec.yaml
    }
  }

  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updateUrl = prefs.getString(_updateUrlKey) ?? defaultUpdateUrl;

      // Skip if no update URL is configured (development mode)
      if (updateUrl == null || updateUrl.isEmpty) {
        debugPrint('Update checking disabled - no update URL configured');
        return null;
      }

      // Check if we're in a delayed state
      final delayedUntil = prefs.getInt(_delayedUpdateKey) ?? 0;
      if (delayedUntil > DateTime.now().millisecondsSinceEpoch) {
        return null; // Still in delay period
      }

      final currentVersion = await getCurrentVersion();

      final response = await http.get(
        Uri.parse(updateUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'RecordsApp/$currentVersion',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final latestVersion = data['version'] as String;
          final downloadUrl = data['download_url'] as String;
          final releaseNotes = data['release_notes'] as String? ?? '';

          // Save latest version info
          await prefs.setString(_latestVersionKey, latestVersion);
          await prefs.setInt(_lastUpdateCheckKey, DateTime.now().millisecondsSinceEpoch);

          if (_isNewerVersion(currentVersion, latestVersion)) {
            return {
              'current_version': currentVersion,
              'latest_version': latestVersion,
              'download_url': downloadUrl,
              'release_notes': releaseNotes,
              'has_update': true,
            };
          }
        } catch (jsonError) {
          debugPrint('Error parsing update response: $jsonError');
          debugPrint('Response body: ${response.body}');
          // Return null to indicate update check failed
          return null;
        }
      }

      return {
        'current_version': currentVersion,
        'latest_version': currentVersion,
        'has_update': false,
      };
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      // Ensure both have same length by padding with zeros
      while (currentParts.length < latestParts.length) {
        currentParts.add(0);
      }
      while (latestParts.length < currentParts.length) {
        latestParts.add(0);
      }

      for (int i = 0; i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  Future<void> delayUpdateFor24Hours() async {
    final prefs = await SharedPreferences.getInstance();
    final delayUntil = DateTime.now().add(const Duration(hours: 24));
    await prefs.setInt(_delayedUpdateKey, delayUntil.millisecondsSinceEpoch);
  }

  Future<bool> downloadAndInstallUpdate(String downloadUrl, {Function(double)? onProgress}) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(downloadUrl);
      final filePath = path.join(tempDir.path, fileName);

      // Download the update file
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // For Windows, expect .exe or .msi file
        // For Linux, expect .AppImage or .deb file
        // For macOS, expect .dmg file

        if (Platform.isWindows) {
          return await _installWindowsUpdate(filePath);
        } else if (Platform.isLinux) {
          return await _installLinuxUpdate(filePath);
        } else if (Platform.isMacOS) {
          return await _installMacOSUpdate(filePath);
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error downloading/installing update: $e');
      return false;
    }
  }

  Future<bool> _installWindowsUpdate(String filePath) async {
    try {
      // For Windows, launch the installer and exit current app
      await Process.start('cmd', ['/c', 'start', '', filePath], mode: ProcessStartMode.detached);

      // Exit current application after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        exit(0);
      });

      return true;
    } catch (e) {
      debugPrint('Error installing Windows update: $e');
      return false;
    }
  }

  Future<bool> _installLinuxUpdate(String filePath) async {
    try {
      final file = File(filePath);

      if (filePath.endsWith('.AppImage')) {
        // Make executable and replace current executable
        await Process.run('chmod', ['+x', filePath]);

        // Get current executable path
        final currentExe = Platform.resolvedExecutable;

        // Replace current executable with new one
        await file.copy(currentExe);

        // Restart application
        await Process.start(currentExe, [], mode: ProcessStartMode.detached);
        exit(0);
      } else if (filePath.endsWith('.deb')) {
        // Install .deb package
        await Process.run('dpkg', ['-i', filePath]);
      }

      return true;
    } catch (e) {
      debugPrint('Error installing Linux update: $e');
      return false;
    }
  }

  Future<bool> _installMacOSUpdate(String filePath) async {
    try {
      if (filePath.endsWith('.dmg')) {
        // Mount DMG and copy app to Applications
        await Process.run('hdiutil', ['attach', filePath]);
        // Implementation would depend on your DMG structure
      }

      return true;
    } catch (e) {
      debugPrint('Error installing macOS update: $e');
      return false;
    }
  }

  Future<void> setUpdateUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_updateUrlKey, url);
  }

  Future<String> getUpdateUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_updateUrlKey) ?? defaultUpdateUrl ?? '';
  }

  Future<void> clearDelayedUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_delayedUpdateKey);
  }

  Future<bool> shouldCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we're in a delayed state
    final delayedUntil = prefs.getInt(_delayedUpdateKey) ?? 0;
    if (delayedUntil > DateTime.now().millisecondsSinceEpoch) {
      return false;
    }

    // Check if we've checked recently (don't check more than once per hour)
    final lastCheck = prefs.getInt(_lastUpdateCheckKey) ?? 0;
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;

    return lastCheck < hourAgo;
  }
}