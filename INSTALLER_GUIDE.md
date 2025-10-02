# Windows Installer Guide

## Professional Installer Features

Your Records app now has a **professional Windows installer** with:

✅ **One-Click Installation** - Simple wizard-based installation
✅ **Program Files Integration** - Installs to proper Windows location
✅ **Start Menu Shortcuts** - Easy access from Start Menu
✅ **Desktop Icon** - Optional desktop shortcut
✅ **Auto-Uninstaller** - Clean uninstallation through Windows Settings
✅ **Automatic Upgrades** - Detects and replaces old versions
✅ **Admin Rights Handling** - Proper elevation for system-wide install
✅ **Modern UI** - Clean, professional installer interface

## What the Installer Does

### During Installation:
1. Checks for previous version and uninstalls it automatically
2. Copies application files to `C:\Program Files\Records\`
3. Creates Start Menu folder with shortcuts
4. Optionally creates desktop shortcut (user choice)
5. Registers application in Windows "Programs and Features"
6. Optionally launches the application after installation

### File Structure After Installation:
```
C:\Program Files\Records\
├── records.exe              (Main application)
├── flutter_windows.dll      (Flutter runtime)
├── *.dll files              (Dependencies)
└── data/                    (Application data)

Start Menu:
📁 Records
  ├── Records (launches app)
  └── Uninstall Records
```

## How Users Install

### Step 1: Download
Go to: `https://github.com/kinetiq-labs/records/releases`
Download: `records-v1.0.0-windows-setup.exe`

### Step 2: Run Installer
1. Double-click the downloaded `.exe` file
2. Windows may show security warning → Click **"More info"** → **"Run anyway"**
3. Allow admin privileges when prompted (UAC dialog)

### Step 3: Follow Wizard
1. **Welcome screen** → Click **Next**
2. **Installation location** → Keep default or choose custom → **Next**
3. **Start Menu folder** → Keep default → **Next**
4. **Desktop icon** → Check box if desired → **Next**
5. **Ready to install** → Click **Install**
6. **Completing setup** → Check "Launch Records" → **Finish**

### Installation Time:
- Download: ~30 seconds (20-30 MB file)
- Installation: ~10 seconds
- **Total: Less than 1 minute!**

## How to Distribute

### For End Users:
Share this simple message:
```
📥 Download Records App
https://github.com/kinetiq-labs/records/releases

1. Click "records-v1.0.0-windows-setup.exe"
2. Run the installer
3. Follow the wizard
4. Done!
```

### For Technical Users:
```
Installation via command line (silent install):
records-v1.0.0-windows-setup.exe /SILENT

Unattended install with all defaults:
records-v1.0.0-windows-setup.exe /VERYSILENT /NORESTART
```

## Creating New Release with Installer

Every time you create a new release tag, GitHub automatically builds the installer:

```bash
# Update version in pubspec.yaml
version: 1.1.0+2

# Commit and tag
git add pubspec.yaml
git commit -m "Bump version to 1.1.0"
git tag v1.1.0
git push origin main
git push origin v1.1.0
```

GitHub Actions will automatically:
1. ✅ Build Flutter app for Windows
2. ✅ Create installer with Inno Setup
3. ✅ Upload `records-v1.1.0-windows-setup.exe` to GitHub Releases

## Installer Customization

### To Modify Installer Settings:
Edit: `installer/installer-template.iss`

**Common customizations:**

```iss
; Change installation folder
DefaultDirName={autopf}\YourAppName

; Require desktop icon by default
Name: "desktopicon"; Description: "..."; Flags: checkedonce

; Add custom license file
LicenseFile=LICENSE.txt

; Change installer compression
Compression=lzma2/ultra64

; Add custom installer icon
SetupIconFile=assets\icons\app_icon.ico
```

After editing, commit and push:
```bash
git add installer/installer-template.iss
git commit -m "Update installer configuration"
git push origin main
```

## Uninstallation

Users can uninstall via:

### Method 1: Windows Settings
1. Windows Settings → Apps → Apps & features
2. Search "Records"
3. Click → Uninstall

### Method 2: Start Menu
1. Open Start Menu
2. Find "Records" folder
3. Click "Uninstall Records"

### Method 3: Control Panel
1. Control Panel → Programs → Uninstall a program
2. Select "Records"
3. Click Uninstall

**Clean Uninstall:**
- Removes all program files
- Removes shortcuts
- Removes registry entries
- Keeps user data (optional to preserve settings)

## Troubleshooting

### "Windows protected your PC" Warning
**Cause:** App is not digitally signed
**Solution:**
- Click "More info"
- Click "Run anyway"
- Or: Sign the installer (see Code Signing section)

### Installation Fails
**Cause:** Previous version not properly uninstalled
**Solution:**
- Manually uninstall old version first
- Or: Installer should auto-detect and remove it

### Can't Install (Access Denied)
**Cause:** Insufficient permissions
**Solution:**
- Right-click installer → "Run as administrator"

## Code Signing (Professional Distribution)

For production, digitally sign your installer to avoid security warnings:

### Steps:
1. **Get Code Signing Certificate** (~$100-500/year)
   - DigiCert, Sectigo, SSL.com
   - Or use free: Let's Encrypt (limited support)

2. **Add Signing to Workflow**
   ```yaml
   - name: Sign Installer
     run: |
       signtool sign /f certificate.pfx /p ${{ secrets.CERT_PASSWORD }} /tr http://timestamp.digicert.com /td sha256 /fd sha256 installer_output\records-*.exe
   ```

3. **Store Certificate Securely**
   - Add certificate to GitHub Secrets
   - Never commit certificate to repository

**Benefits of Signing:**
- No security warnings
- Users trust the installer
- Professional appearance
- Required for enterprise distribution

## Advanced Features

### Custom Install Screens
Edit installer template to add:
- Custom welcome message
- Terms and conditions
- User registration
- Component selection

### Multi-Language Support
Add language files to installer:
```iss
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
```

### Custom Actions
Run scripts during installation:
```iss
[Run]
; Install Visual C++ Redistributable
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/quiet"; StatusMsg: "Installing dependencies..."
```

## Testing Installer Locally

If you have access to a Windows machine:

1. **Install Inno Setup**
   - Download from: https://jrsoftware.org/isdl.php
   - Install on Windows PC

2. **Build Flutter App**
   ```bash
   flutter build windows --release
   ```

3. **Compile Installer**
   - Open `installer/installer-template.iss` in Inno Setup
   - Click "Compile" (or press Ctrl+F9)
   - Installer created in `installer_output/`

4. **Test Installation**
   - Run the generated `.exe`
   - Test all features
   - Verify uninstallation works

## Monitoring Installer Downloads

Check GitHub Insights to see:
- Download statistics
- Most popular versions
- User engagement

Go to: `https://github.com/kinetiq-labs/records/graphs/traffic`

## Next Steps

After setting up the installer:

1. ✅ **Test the installer** - Download from GitHub and install
2. ✅ **Document installation** - Create user guide
3. ✅ **Share with users** - Distribute download link
4. ✅ **Monitor feedback** - Collect user installation experiences
5. ✅ **Consider signing** - Get code signing certificate for production

---

**Your professional Windows installer is ready!** 🚀

Users can now install Records with a single click, just like any professional Windows application.
