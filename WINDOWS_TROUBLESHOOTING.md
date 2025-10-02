# Windows Installation Troubleshooting Guide

## Problem: App Opens and Closes Immediately

### Symptoms:
- App installs successfully
- Desktop icon appears
- When you double-click the app, it opens briefly then closes
- No error message appears
- App works fine on some computers but not others

### Root Cause:
Missing **Visual C++ Runtime** libraries that Flutter Windows apps depend on.

---

## Solution 1: Install Visual C++ Redistributable (Quick Fix)

### Steps:
1. **Download** the redistributable:
   - Direct link: https://aka.ms/vs/17/release/vc_redist.x64.exe
   - Or search: "Visual C++ Redistributable 2022" on Microsoft's website

2. **Run the installer**:
   - Double-click `vc_redist.x64.exe`
   - Click "Install"
   - Accept license agreement
   - Wait for installation to complete

3. **Restart your computer**

4. **Try opening Records app again** - It should now work!

---

## Solution 2: Reinstall Records App (Automatic Fix)

If you're using **Records v1.0.1 or later**, the installer automatically installs the Visual C++ Runtime.

### Steps:
1. **Uninstall** the current version:
   - Windows Settings → Apps → Records → Uninstall

2. **Download** the latest version:
   - Go to: https://github.com/Kinetiq-labs/records/releases
   - Download: `records-vX.X.X-windows-setup.exe`

3. **Install** the new version:
   - Run the installer
   - It will automatically install Visual C++ Runtime if needed

4. **Launch the app** - Should work now!

---

## Solution 3: Check for Missing DLLs

If the above solutions don't work, check which DLLs are missing:

### Using Dependency Walker:
1. Download **Dependencies** (modern alternative): https://github.com/lucasg/Dependencies/releases
2. Open `records.exe` with Dependencies
3. Look for missing DLLs (shown in red)
4. Common missing DLLs:
   - `msvcp140.dll`
   - `vcruntime140.dll`
   - `vcruntime140_1.dll`
   - `mf.dll` (Media Foundation)

### Fix Missing DLLs:
- **For msvcp/vcruntime DLLs**: Install Visual C++ Redistributable (Solution 1)
- **For mf.dll**: Install Windows Media Feature Pack (Windows N/KN editions only)

---

## Solution 4: Windows N/KN Edition Fix

If you're using **Windows N** or **Windows KN** (European/Korean editions without media features):

### Install Media Feature Pack:
1. Go to Windows Settings
2. Apps → Optional Features → Add a feature
3. Search for "Media Feature Pack"
4. Install it
5. Restart computer
6. Try Records app again

---

## Solution 5: Check Windows Compatibility

### System Requirements:
- **OS**: Windows 10 (64-bit) or later
- **Architecture**: x64 (64-bit)
- **RAM**: 4GB minimum
- **Disk Space**: 200MB free

### Check Your Windows Version:
1. Press `Win + R`
2. Type: `winver`
3. Press Enter
4. Verify you have Windows 10 or 11 (64-bit)

---

## Solution 6: Run as Administrator

Sometimes permission issues cause silent crashes:

1. **Right-click** Records app icon
2. Select **"Run as administrator"**
3. Click **"Yes"** on UAC prompt

If this works, you can make it permanent:
1. Right-click Records icon
2. Properties → Compatibility tab
3. Check ☑️ "Run this program as an administrator"
4. Click OK

---

## Solution 7: Check Antivirus/Firewall

Some antivirus programs block unsigned applications:

1. **Check your antivirus quarantine**:
   - Look for `records.exe` in quarantine
   - Restore it and add to whitelist

2. **Temporarily disable antivirus** and try launching:
   - If it works, add Records to antivirus exceptions
   - Re-enable antivirus after testing

3. **Windows Defender**:
   - Windows Security → Virus & threat protection
   - Manage settings → Add exclusion
   - Add folder: `C:\Program Files\Records`

---

## Solution 8: Check Event Viewer for Errors

To see the actual crash error:

1. Press `Win + X` → Event Viewer
2. Navigate to: **Windows Logs** → **Application**
3. Look for recent errors from "records.exe"
4. Note the error details

Common errors and fixes:
- **"Application failed to start (0xc000007b)"**: Install Visual C++ Redistributable
- **"DLL not found"**: See Solution 3
- **"Access denied"**: Run as administrator (Solution 6)

---

## Solution 9: Database File Permissions

If app crashes after opening:

1. Navigate to database location:
   ```
   C:\Users\YourUsername\AppData\Local\Records
   ```

2. Check file permissions:
   - Right-click folder → Properties → Security
   - Ensure your user account has "Full control"

3. Delete corrupted database (if any):
   - Delete `records.db` (your data will be lost!)
   - App will create a new database on next launch

---

## Solution 10: Clean Reinstall

Complete removal and fresh install:

### Steps:
1. **Uninstall**:
   - Windows Settings → Apps → Records → Uninstall

2. **Delete leftover files**:
   ```
   C:\Program Files\Records
   C:\Users\YourUsername\AppData\Local\Records
   ```

3. **Restart computer**

4. **Reinstall** from latest release

---

## Still Not Working?

### Get Debug Information:

1. **Run from Command Prompt** to see errors:
   ```cmd
   cd "C:\Program Files\Records"
   records.exe
   ```
   - Any error messages will appear in the terminal

2. **Check for crash dump**:
   - Look in: `C:\Users\YourUsername\AppData\Local\CrashDumps`

3. **Report the issue**:
   - GitHub: https://github.com/Kinetiq-labs/records/issues
   - Email: info@kinetiq.site
   - Include:
     - Windows version
     - Error messages from Event Viewer
     - Output from running in Command Prompt

---

## Prevention: For Future Installations

When installing on a **clean Windows system**, always install:

1. **Visual C++ Redistributable** (most important)
   - https://aka.ms/vs/17/release/vc_redist.x64.exe

2. **Windows Updates**
   - Ensure Windows is fully updated

3. **Media Feature Pack** (for Windows N/KN only)

---

## Developer Note

Starting from **v1.0.1**, the Records installer automatically includes:
- ✅ Visual C++ Runtime check and installation
- ✅ Dependency verification
- ✅ Better error reporting

If you installed an earlier version, please update to the latest release for automatic dependency management.

---

**Last Updated**: January 2025
**Version**: 1.0.0
