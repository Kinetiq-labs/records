# Windows Installation Instructions

## Method 1: Using the Installer (Recommended - Easy)

### Download:
1. Go to: https://github.com/Kinetiq-labs/records/releases
2. Download: `records-v1.0.1-windows-setup.exe` (or latest version)

### Install:
1. **Double-click** the installer file
2. If Windows shows a security warning:
   - Click **"More info"**
   - Click **"Run anyway"**
3. Follow the installation wizard
4. The installer will automatically:
   - Install Visual C++ Runtime (if needed)
   - Create shortcuts
   - Register the app in Windows
5. Click **Finish** to complete

### Launch:
- From Desktop: Double-click **Records** icon
- From Start Menu: Search "Records" and click

---

## Method 2: Using the ZIP File (Portable)

### Download:
1. Go to: https://github.com/Kinetiq-labs/records/releases
2. Download: `records-v1.0.1-windows.zip`

### Extract:
1. **Right-click** the ZIP file
2. Select **"Extract All..."**
3. Choose a location (e.g., `C:\Records` or Desktop)
4. **IMPORTANT**: Extract to a NEW folder, don't extract directly to Desktop/Documents

### Before Running:
**Install Visual C++ Runtime** (required):
1. Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
2. Run the installer
3. Restart your computer

### Launch:
1. Open the extracted folder
2. **Double-click** `records.exe`

---

## ⚠️ Common Mistakes (Why App Crashes)

### Mistake #1: Not Extracting ALL Files
**WRONG:**
```
Desktop/
  └── records.exe  ❌ Missing DLL files!
```

**CORRECT:**
```
Desktop/Records/
  ├── records.exe  ✅
  ├── flutter_windows.dll  ✅
  ├── data/ folder  ✅
  └── [other DLL files]  ✅
```

**Solution**: Extract the ENTIRE ZIP contents, not just the .exe file!

### Mistake #2: Missing Visual C++ Runtime
**Symptom**: App opens and closes immediately

**Solution**: Install from https://aka.ms/vs/17/release/vc_redist.x64.exe

### Mistake #3: Antivirus Blocking
**Symptom**: App deleted or won't run

**Solution**: Add Records folder to antivirus exceptions

---

## Verify Correct Installation

After extraction/installation, you should see these files:

```
Records/
├── records.exe              ← Main application
├── flutter_windows.dll      ← Flutter runtime
├── data/                    ← Application data
│   ├── icudtl.dat
│   └── flutter_assets/
├── msvcp140.dll             ← Visual C++ runtime
├── vcruntime140.dll         ← Visual C++ runtime
├── vcruntime140_1.dll       ← Visual C++ runtime
└── [other plugin DLLs]
```

**If any DLL files are missing**, you extracted incorrectly!

---

## First Launch Checklist

Before running the app for the first time:

- ✅ **Extracted ALL files** from ZIP (not just records.exe)
- ✅ **Installed Visual C++ Runtime** (vc_redist.x64.exe)
- ✅ **Restarted computer** after installing runtime
- ✅ **Disabled antivirus temporarily** (for testing)
- ✅ **Running Windows 10/11 64-bit**

---

## System Requirements

### Minimum:
- **OS**: Windows 10 (64-bit) or later
- **CPU**: Intel Core i3 or equivalent
- **RAM**: 4GB
- **Disk**: 200MB free space
- **Display**: 1280x720 resolution

### Required Software:
- Visual C++ Redistributable 2015-2022 (x64)
  - Auto-installed by installer
  - Manual download: https://aka.ms/vs/17/release/vc_redist.x64.exe

---

## Quick Troubleshooting

### Problem: App doesn't start (no window appears)

**Try these in order:**

1. **Check Task Manager**:
   - Press `Ctrl+Shift+Esc`
   - Look for `records.exe` in Processes
   - If it's there, the app might be hidden
   - Right-click → Bring to Front

2. **Run from Command Prompt** to see errors:
   ```cmd
   cd path\to\Records
   records.exe
   ```
   - Any error messages will appear

3. **Check Event Viewer**:
   - Press `Win+X` → Event Viewer
   - Windows Logs → Application
   - Look for errors from `records.exe`

4. **Missing DLLs**:
   - Download Dependencies tool: https://github.com/lucasg/Dependencies/releases
   - Open `records.exe` with Dependencies
   - Check for red (missing) DLLs

### Problem: "vcruntime140.dll not found"

**Solution**:
Install Visual C++ Runtime: https://aka.ms/vs/17/release/vc_redist.x64.exe

### Problem: "mf.dll not found" (Windows N/KN)

**Solution**:
1. Settings → Apps → Optional Features
2. Add "Media Feature Pack"
3. Restart computer

### Problem: Antivirus deleted the app

**Solution**:
1. Restore from quarantine
2. Add to exceptions:
   - Windows Defender: Settings → Virus & threat protection → Exclusions
   - Add folder: `C:\Program Files\Records` or your extraction location

---

## Advanced: Running Without Installation

For portable/USB drive use:

1. Extract ZIP to USB drive or portable location
2. Install Visual C++ Runtime on target computer (one-time)
3. Run `records.exe` directly from portable location
4. Database will be created in:
   ```
   C:\Users\[Username]\AppData\Local\Records\
   ```

---

## Uninstallation

### If installed with installer:
1. Windows Settings → Apps
2. Find "Records"
3. Click Uninstall

### If using ZIP version:
1. Delete the extracted Records folder
2. Optionally delete data folder:
   ```
   C:\Users\[Username]\AppData\Local\Records\
   ```

---

## Getting Help

If you still can't get it running:

1. **Check troubleshooting guide**: WINDOWS_TROUBLESHOOTING.md
2. **Report issue**:
   - GitHub: https://github.com/Kinetiq-labs/records/issues
   - Email: info@kinetiq.site
3. **Include**:
   - Windows version (Win+R → `winver`)
   - Error messages from Event Viewer
   - Screenshot of extracted folder contents
   - Output from running in Command Prompt

---

## Why Use the Installer vs ZIP?

### Installer (records-setup.exe):
- ✅ Automatic dependency installation
- ✅ Shortcuts created
- ✅ Proper uninstaller
- ✅ Windows integration
- ❌ Requires admin rights

### ZIP (records-windows.zip):
- ✅ Portable (run from USB)
- ✅ No admin rights needed
- ✅ Multiple instances possible
- ❌ Manual dependency installation
- ❌ No automatic updates

**Recommendation**: Use installer for permanent installation on your main computer. Use ZIP for testing or portable use.

---

**Last Updated**: January 2025
**Version**: 1.0.1
