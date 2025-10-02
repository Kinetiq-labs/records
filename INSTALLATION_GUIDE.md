# Records Application - Installation Guide

## Download Links
Download the appropriate version for your operating system:

- **Linux (x64)**: `records-linux-x64.tar.gz` (67MB)
- **Windows**: Cross-compilation not available from Linux - requires Windows build machine
- **macOS**: Cross-compilation not available from Linux - requires macOS build machine

## Admin Credentials
**Email**: `admin@records.app`
**Password**: `root123`

## Installation Instructions

### Linux Installation

1. **Download** the `records-linux-x64.tar.gz` file
2. **Extract** the archive:
   ```bash
   tar -xzf records-linux-x64.tar.gz
   ```
3. **Make executable** (if needed):
   ```bash
   chmod +x bundle/records
   ```
4. **Run** the application:
   ```bash
   ./bundle/records
   ```

#### Optional: Create Desktop Entry (Linux)
Create a desktop shortcut by saving this to `~/.local/share/applications/records.desktop`:
```ini
[Desktop Entry]
Name=Records
Comment=Business Records Management System
Exec=/path/to/records/bundle/records
Icon=/path/to/records/bundle/data/flutter_assets/assets/icons/app_icon.png
Terminal=false
Type=Application
Categories=Office;Finance;
```

### Windows Installation
**Note**: Windows builds must be created on a Windows machine. To build for Windows:

1. Install Flutter on Windows
2. Clone the repository
3. Run: `flutter build windows --release`
4. Distribute the `build/windows/runner/Release/` folder

### macOS Installation
**Note**: macOS builds must be created on a macOS machine. To build for macOS:

1. Install Flutter on macOS
2. Clone the repository
3. Run: `flutter build macos --release`
4. Distribute the `.app` bundle from `build/macos/Build/Products/Release/`

## System Requirements

### Linux
- Ubuntu 18.04+ or equivalent
- glibc 2.27+
- X11 or Wayland display server
- Minimum 2GB RAM
- 200MB free disk space

### Windows
- Windows 10/11 (64-bit)
- Minimum 2GB RAM
- 200MB free disk space

### macOS
- macOS 10.14+
- Minimum 2GB RAM
- 200MB free disk space

## Features
- Multi-language support (English, Arabic, Urdu)
- Customer management
- Transaction recording
- PDF receipt generation
- Real-time gold/silver price tracking
- Data analytics and reporting
- Cloud synchronization with Supabase
- Auto-update functionality

## First Run
1. Launch the application
2. Login with admin credentials:
   - Email: `admin@records.app`
   - Password: `root123`
3. Access admin dashboard to manage users and system settings
4. Regular users can be created from the admin panel

## Support
For technical support or issues, contact the development team.

## Security Notes
- Change the default admin password after first login
- Use strong passwords for all user accounts
- Regularly backup your database
- Keep the application updated