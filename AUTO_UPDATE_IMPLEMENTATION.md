# Auto-Update System Implementation

## Overview

This document describes the complete implementation of an auto-update system for the Records Flutter desktop application. The system allows users to receive update notifications, download and install updates automatically, and includes a 24-hour delay option for deferred updates.

## Features Implemented

### 1. Update Service (`lib/services/app_update_service.dart`)
- **Version checking**: Compares current app version with latest available version
- **Update downloads**: Downloads update files from configurable URL
- **Platform-specific installation**: Handles Windows (.exe/.msi), Linux (.AppImage/.deb), and macOS (.dmg) installers
- **24-hour delay logic**: Implements user-requested delay functionality
- **Configurable update URL**: Allows customization of update server endpoint

### 2. Update Provider (`lib/providers/update_provider.dart`)
- **State management**: Manages update checking, downloading, and installation states
- **Progress tracking**: Tracks download progress and status updates
- **Error handling**: Manages and displays update-related errors
- **Auto-check configuration**: Allows enabling/disabling automatic update checks

### 3. Update Notification Dialog (`lib/widgets/update_notification_dialog.dart`)
- **Multi-language support**: Supports English, Urdu, and Arabic languages
- **Update information display**: Shows current version, latest version, and release notes
- **User action buttons**: "Update Now" and "Later" options
- **Visual feedback**: Progress indicators and status updates

### 4. Update Checker Widget (`lib/widgets/update_checker.dart`)
- **Background monitoring**: Automatically checks for updates periodically
- **Visual indicators**: Shows update availability badge in app corner
- **Download progress**: Displays progress bar during download/installation
- **Non-intrusive integration**: Wraps main app without affecting functionality

### 5. Settings Integration (`lib/screens/settings_screen.dart`)
- **Update management**: Manual update checks and installation controls
- **Status display**: Shows current version and update availability
- **Progress monitoring**: Real-time download and installation progress
- **Error management**: Displays and allows clearing of update errors

## How It Works

### Automatic Update Flow

1. **Initialization**:
   - App starts and initializes `UpdateProvider`
   - `UpdateChecker` widget wraps the main app
   - System checks for updates after 2-second delay

2. **Update Detection**:
   - Service makes HTTP request to configured update server
   - Compares returned version with current app version
   - Respects 24-hour delay if user previously selected "Later"

3. **User Notification**:
   - If update available, shows notification dialog automatically
   - User can choose "Update Now" or "Later"
   - "Later" option delays next check for 24 hours

4. **Update Installation**:
   - Downloads update file to temporary directory
   - Platform-specific installation process:
     - **Windows**: Launches installer and exits current app
     - **Linux**: Replaces executable (AppImage) or installs package (.deb)
     - **macOS**: Mounts DMG and handles installation

### Manual Update Flow

1. **Settings Access**:
   - User navigates to Settings → App Updates section
   - Can manually trigger update check
   - View current version and update status

2. **Manual Installation**:
   - If update available, user can click "Update Now"
   - Progress shown in settings screen
   - Same installation process as automatic updates

## Configuration

### Update Server Setup

You need to set up a server endpoint that returns version information in this format:

```json
{
  "version": "1.1.0",
  "download_url": "https://your-server.com/releases/records-v1.1.0-windows.exe",
  "release_notes": "Bug fixes and performance improvements"
}
```

### Default Configuration

- **Update URL**: `https://your-server.com/api/app-version` (configurable)
- **Check interval**: 6 hours (configurable)
- **Delay period**: 24 hours (fixed)
- **Timeout**: 10 seconds for version checks

### Customization Options

```dart
// Change update server URL
await updateProvider.setUpdateUrl('https://your-custom-server.com/api/version');

// Force immediate update check
await updateProvider.forceCheckForUpdates();

// Clear delayed update (allow immediate checking)
await updateProvider.clearDelayedUpdate();
```

## Dependencies Added

- `package_info_plus: ^4.2.0` - For getting current app version

## File Structure

```
lib/
├── services/
│   └── app_update_service.dart     # Core update functionality
├── providers/
│   └── update_provider.dart        # State management
├── widgets/
│   ├── update_checker.dart         # Background monitoring
│   └── update_notification_dialog.dart # User interface
└── screens/
    └── settings_screen.dart        # Manual update controls
```

## Security Considerations

1. **HTTPS Required**: All update URLs should use HTTPS for security
2. **File Validation**: Consider adding file hash verification
3. **Signed Packages**: Use signed installers for production
4. **Error Handling**: Graceful degradation if update server unavailable

## Platform-Specific Notes

### Windows
- Supports `.exe` and `.msi` installers
- Automatically launches installer and exits current app
- Requires admin privileges for system-wide installation

### Linux
- Supports `.AppImage` (self-contained) and `.deb` packages
- AppImage: Direct executable replacement
- DEB: Uses `dpkg` for installation

### macOS
- Supports `.dmg` disk images
- Requires additional implementation for app bundle handling
- May need code signing for distribution

## Testing

To test the update system:

1. **Mock Server**: Set up a test server returning version info
2. **Version Increment**: Temporarily modify current version to trigger updates
3. **Network Conditions**: Test with slow/unreliable connections
4. **Error Scenarios**: Test server unavailability and invalid responses

## Future Enhancements

1. **Delta Updates**: Download only changed files for faster updates
2. **Rollback**: Ability to revert to previous version
3. **Beta Channel**: Support for beta/preview releases
4. **Automatic Restart**: Option to restart app after update
5. **Update Scheduling**: Allow users to schedule update times

## Troubleshooting

### Common Issues

1. **Version Check Fails**: Verify internet connection and server availability
2. **Download Fails**: Check disk space and write permissions
3. **Installation Fails**: Ensure proper file permissions and admin rights
4. **Updates Not Shown**: Check if 24-hour delay is active

### Debug Information

Enable debug prints by checking the console for:
- Update check results
- Download progress
- Installation status
- Error messages

## Implementation Complete

The auto-update system is now fully integrated into your Records application. Users will automatically receive update notifications, can choose to update immediately or delay for 24 hours, and have manual control through the Settings screen.