# Windows Build Guide for Records App

## Prerequisites (Install on Windows machine)

### 1. Install Git
- Download: https://git-scm.com/download/win
- Use default settings during installation

### 2. Install Flutter
1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter`
3. Add to PATH: `C:\flutter\bin`

### 3. Install Visual Studio 2022 Community
- Download: https://visualstudio.microsoft.com/vs/community/
- **Important**: During installation, select:
  - "Desktop development with C++"
  - Windows 10/11 SDK
  - MSVC compiler

### 4. Verify Installation
Open Command Prompt and run:
```cmd
flutter doctor
```
Should show ✅ for Windows desktop

## Building the App

### Step 1: Clone Repository
```cmd
git clone [YOUR_REPOSITORY_URL]
cd Records
```

### Step 2: Get Dependencies
```cmd
flutter clean
flutter pub get
```

### Step 3: Build Windows Release
```cmd
flutter build windows --release
```

### Step 4: Create Distribution Package
The built app will be in: `build\windows\runner\Release\`

Create a ZIP file containing:
- All files from `build\windows\runner\Release\`
- Name it: `records-windows-x64.zip`

## Distribution Contents
The ZIP should contain:
```
records-windows-x64/
├── records.exe          (main executable)
├── *.dll files          (required libraries)
├── data/               (Flutter assets)
└── plugins/            (Flutter plugins)
```

## File Size Estimate
- Windows build: ~40-80MB
- ZIP compressed: ~20-40MB

## Testing
Before distributing:
1. Test the .exe on the build machine
2. Test on another Windows machine (if possible)
3. Verify all features work (database, PDF generation, etc.)

## Upload to Website
Upload the `records-windows-x64.zip` alongside the Linux version.

## Admin Credentials (same as Linux)
- Email: admin@records.app
- Password: root123

## Troubleshooting

### "VCRUNTIME140.dll missing"
- Install Visual C++ Redistributable: https://aka.ms/vs/17/release/vc_redist.x64.exe

### Build fails
- Ensure Visual Studio has "Desktop development with C++"
- Run `flutter doctor` to check setup
- Try `flutter clean` then rebuild

### Large file size
- Windows builds are typically larger than Linux
- This is normal for Flutter desktop apps