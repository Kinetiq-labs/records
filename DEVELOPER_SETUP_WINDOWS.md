# Developer Setup Guide - Windows

This guide will help you set up the Records app development environment on Windows using VS Code.

## Prerequisites Installation

### 1. Install Git
**Download**: https://git-scm.com/download/win

1. Run the installer
2. Use default settings (recommended)
3. Verify installation:
   ```cmd
   git --version
   ```

### 2. Install Flutter SDK

**Download**: https://docs.flutter.dev/get-started/install/windows

#### Quick Steps:
1. Download Flutter SDK: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip
2. Extract to `C:\flutter` (or any location WITHOUT spaces)
3. Add Flutter to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" under User variables
   - Add: `C:\flutter\bin`
4. Restart Command Prompt
5. Verify:
   ```cmd
   flutter --version
   ```

### 3. Install Visual Studio (Required for Windows Desktop)

**Download**: https://visualstudio.microsoft.com/downloads/

**Install Visual Studio 2022 Community Edition**:
1. Run the installer
2. Select workload: **"Desktop development with C++"**
3. Click Install (this will take 10-30 minutes)

### 4. Install VS Code

**Download**: https://code.visualstudio.com/

**Install Extensions** (in VS Code):
1. Open VS Code
2. Click Extensions icon (left sidebar)
3. Install:
   - **Flutter** (by Dart Code)
   - **Dart** (by Dart Code)
   - **GitLens** (optional, helpful for Git)

## Project Setup

### Step 1: Clone the Repository

Open Command Prompt or PowerShell:

```cmd
# Navigate to where you want the project
cd C:\Users\YourName\Documents

# Clone the repository
git clone https://github.com/Kinetiq-labs/records.git

# Navigate into project
cd records
```

### Step 2: Verify Flutter Setup

```cmd
# Check Flutter doctor
flutter doctor

# Enable Windows desktop
flutter config --enable-windows-desktop

# Run doctor again to verify
flutter doctor -v
```

**Expected output should show**:
- ✅ Flutter SDK
- ✅ Windows toolchain (Visual Studio)
- ✅ VS Code
- ✅ Connected device (Windows)

**Fix any ❌ issues before proceeding!**

### Step 3: Get Dependencies

```cmd
# Install all packages
flutter pub get
```

**If you see errors about package versions**, that's expected - we'll fix them.

### Step 4: Open in VS Code

```cmd
# Open VS Code in the project folder
code .
```

Or:
- Open VS Code
- File → Open Folder
- Select the `records` folder

## Running the App

### Method 1: From VS Code (Recommended)

1. **Select Device**:
   - Press `Ctrl+Shift+P`
   - Type: "Flutter: Select Device"
   - Choose: **Windows (desktop-windows)**

2. **Run the App**:
   - Press `F5` (Start Debugging)
   - Or press `Ctrl+F5` (Run Without Debugging)
   - Or click the ▶️ button in top-right

### Method 2: From Command Line

```cmd
# Run in debug mode
flutter run -d windows

# Run in release mode
flutter run -d windows --release
```

### First Run Notes

- **First run takes 5-15 minutes** (compiling C++ code)
- Subsequent runs are much faster (1-2 minutes)
- Debug mode is slower but easier to debug
- Release mode is faster but harder to debug

## Common Issues & Fixes

### Issue 1: "No devices found"

**Solution**:
```cmd
flutter config --enable-windows-desktop
flutter devices
```

Should show:
```
Windows (desktop) • windows • windows-x64 • Microsoft Windows
```

### Issue 2: "Visual Studio not found"

**Solution**:
1. Install Visual Studio 2022 with "Desktop development with C++"
2. Restart computer
3. Run: `flutter doctor`

### Issue 3: Package version conflicts

**Solution**:
```cmd
# Clean and reinstall
flutter clean
flutter pub get
```

### Issue 4: Build errors about "withValues"

**Already fixed in the repo!** Just make sure you have the latest code:
```cmd
git pull origin main
flutter clean
flutter pub get
```

### Issue 5: "MSBuild not found"

**Solution**:
Add MSBuild to PATH:
1. Add: `C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin`
2. Restart Command Prompt

### Issue 6: App crashes immediately

**Solution**:
Run in debug mode to see errors:
```cmd
flutter run -d windows
```

Check the console for error messages.

## Building Release Version

### Build EXE

```cmd
flutter build windows --release
```

**Output location**:
```
build\windows\x64\runner\Release\
```

This folder contains:
- `records.exe` - Main application
- `flutter_windows.dll` - Flutter runtime
- `data\` folder - Assets and resources
- Other DLL files - Dependencies

**⚠️ Important**: You must distribute the ENTIRE `Release` folder, not just the .exe!

### Test the Build

```cmd
cd build\windows\x64\runner\Release
records.exe
```

## Project Structure

```
records/
├── lib/                    # Dart source code
│   ├── main.dart          # App entry point
│   ├── models/            # Data models
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable widgets
│   ├── services/          # Business logic
│   ├── providers/         # State management
│   └── utils/             # Utilities
├── windows/               # Windows native code
│   └── runner/            # Windows runner (C++)
├── assets/                # Images, fonts
├── fonts/                 # Font files
├── pubspec.yaml          # Dependencies
└── README.md             # Documentation
```

## Development Workflow

### Making Changes

1. **Edit Code** in VS Code
2. **Hot Reload**: Press `r` in terminal or `Ctrl+F5` in VS Code
3. **Hot Restart**: Press `R` in terminal or restart debug session
4. **Full Rebuild**:
   ```cmd
   flutter clean
   flutter run -d windows
   ```

### Debugging

1. **Set Breakpoints**: Click left margin in VS Code
2. **Start Debugging**: Press `F5`
3. **Debug Console**: View → Debug Console
4. **Variables**: See values in Debug sidebar

### Git Workflow

```cmd
# Check status
git status

# Create a branch for your changes
git checkout -b fix-crash-issue

# Make changes, then commit
git add .
git commit -m "Fix: Describe what you fixed"

# Push to GitHub
git push origin fix-crash-issue
```

## Troubleshooting Development Issues

### Clear Everything and Start Fresh

```cmd
# Clean Flutter build
flutter clean

# Clear pub cache (if needed)
flutter pub cache repair

# Get dependencies again
flutter pub get

# Rebuild
flutter run -d windows
```

### Check Flutter Health

```cmd
# Full diagnostic
flutter doctor -v

# Check for Flutter updates
flutter upgrade

# Downgrade if needed
flutter downgrade 3.24.0
```

### View Logs

**While app is running**:
- All `print()` and `debugPrint()` statements appear in terminal
- Errors show in red
- Use `print('DEBUG: variable = $variable')` for debugging

**Windows Event Viewer** (for crashes):
1. Press `Win+X` → Event Viewer
2. Windows Logs → Application
3. Look for errors from `flutter.exe` or `records.exe`

## Performance Tips

### Speed Up Builds

1. **Use Debug mode** during development (faster builds)
2. **Use Hot Reload** (`r`) instead of restarting
3. **Close other apps** to free RAM
4. **Use SSD** for project location

### Debug Performance Issues

```cmd
# Run with performance overlay
flutter run -d windows --profile

# Analyze build time
flutter build windows --verbose
```

## Testing the App

### Manual Testing

1. **Test login**: Use credentials from README
2. **Test database**: Create/read/update/delete records
3. **Test UI**: Resize window, check themes
4. **Test closing**: Ensure data persists

### Run Tests (if available)

```cmd
flutter test
```

## Creating a Build for Distribution

### Step-by-Step:

1. **Update version** in `pubspec.yaml`:
   ```yaml
   version: 1.0.2+2
   ```

2. **Clean build**:
   ```cmd
   flutter clean
   flutter pub get
   ```

3. **Build release**:
   ```cmd
   flutter build windows --release
   ```

4. **Create ZIP**:
   - Navigate to: `build\windows\x64\runner\Release`
   - Select all files
   - Right-click → Send to → Compressed folder
   - Name it: `records-v1.0.2-windows.zip`

5. **Test the ZIP**:
   - Extract to a different location
   - Run `records.exe`
   - Verify it works

## Advanced: Creating Installer

If you want to create an installer like the GitHub releases:

1. **Install Inno Setup**:
   - Download: https://jrsoftware.org/isdl.php

2. **Build the app**:
   ```cmd
   flutter build windows --release
   ```

3. **Compile installer**:
   - Open: `installer\installer-template.iss` in Inno Setup
   - Update version number
   - Click "Compile"
   - Installer will be in: `installer_output\`

## Getting Help

### Resources:
- **Flutter Docs**: https://docs.flutter.dev/
- **Flutter Windows**: https://docs.flutter.dev/platform-integration/windows/building
- **Project Issues**: https://github.com/Kinetiq-labs/records/issues

### If App Crashes:
1. Run with verbose logging:
   ```cmd
   flutter run -d windows -v
   ```
2. Copy all error messages
3. Check Event Viewer for crash details
4. Share errors with the team

### Community:
- GitHub Issues: Report bugs and ask questions
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: Tag with `flutter` and `windows`

---

## Quick Reference

```cmd
# Setup
flutter doctor                    # Check installation
flutter config --enable-windows-desktop
flutter pub get                   # Install dependencies

# Run
flutter run -d windows           # Debug mode
flutter run -d windows --release # Release mode

# Build
flutter build windows --release  # Create distributable

# Clean
flutter clean                    # Remove build cache
flutter pub cache repair         # Fix package issues

# Git
git pull origin main             # Get latest code
git status                       # Check changes
git add .                        # Stage changes
git commit -m "message"          # Commit
git push origin branch-name      # Push to GitHub
```

---

**Last Updated**: January 2025
**Flutter Version**: 3.24.0
**Tested On**: Windows 10/11 64-bit
