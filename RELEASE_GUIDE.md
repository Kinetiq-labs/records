# Release Guide - Records App

This guide explains how to create and publish releases for the Records application using GitHub Actions.

## Prerequisites

1. **GitHub Account**: Use your company account `kinetiq-labs`
2. **Git Installed**: Ensure Git is installed on your system
3. **GitHub Repository**: Create a repository at `github.com/kinetiq-labs/records`

## Initial Setup

### 1. Configure Git with Company Account

```bash
cd /home/cipher/Documents/Projects/Records

# Set your company credentials
git config user.name "kinetiq-labs"
git config user.email "info@kinetiq.site"
```

### 2. Initialize Git Repository

```bash
# Initialize the repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit - Records v1.0.0"
```

### 3. Connect to GitHub

```bash
# Add your GitHub repository as remote
git remote add origin https://github.com/kinetiq-labs/records.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Creating a Release

### Method 1: Using Git Tags (Recommended)

```bash
# 1. Update version in pubspec.yaml
# Change: version: 1.0.0+1
# To:     version: 1.1.0+2

# 2. Commit version change
git add pubspec.yaml
git commit -m "Bump version to 1.1.0"

# 3. Create and push tag
git tag v1.1.0
git push origin v1.1.0

# 4. GitHub Actions automatically builds Windows & Linux releases!
```

### Method 2: Manual Trigger

1. Go to GitHub repository: `https://github.com/kinetiq-labs/records`
2. Click **Actions** tab
3. Select **Build Windows Release** or **Build Linux Release**
4. Click **Run workflow** button
5. Choose branch and click **Run workflow**

## What Happens Automatically

When you push a tag (e.g., `v1.1.0`):

1. ✅ GitHub Actions detects the tag
2. ✅ Builds Windows release on Windows runner
3. ✅ Builds Linux release on Ubuntu runner
4. ✅ Creates release packages:
   - `records-v1.1.0-windows.zip`
   - `records-v1.1.0-linux.tar.gz`
5. ✅ Uploads to GitHub Releases page
6. ✅ Creates GitHub Release with download links

## Monitoring Build Status

### Check Build Progress:
1. Go to: `https://github.com/kinetiq-labs/records/actions`
2. View running/completed workflows
3. Click on workflow to see detailed logs

### Build Success:
- Green checkmark ✅ = Build successful
- Red X ❌ = Build failed (check logs)

## Download Released Files

### For End Users:
1. Go to: `https://github.com/kinetiq-labs/records/releases`
2. Find latest release (e.g., `v1.1.0`)
3. Download:
   - **Windows users**: `records-v1.1.0-windows.zip`
   - **Linux users**: `records-v1.1.0-linux.tar.gz`

### Installation:
**Windows:**
```bash
1. Extract records-v1.1.0-windows.zip
2. Run records.exe
```

**Linux:**
```bash
tar -xzf records-v1.1.0-linux.tar.gz
cd records
./records
```

## Setting Up Auto-Update URL

After first release is published:

### 1. Get GitHub Release API URL:
```
https://api.github.com/repos/kinetiq-labs/records/releases/latest
```

### 2. Update Code:
Edit `lib/services/app_update_service.dart` (line 18):
```dart
static const String? defaultUpdateUrl =
  'https://api.github.com/repos/kinetiq-labs/records/releases/latest';
```

### 3. Commit and Create New Release:
```bash
git add lib/services/app_update_service.dart
git commit -m "Configure auto-update URL"
git tag v1.0.1
git push origin main
git push origin v1.0.1
```

## Release Checklist

Before creating a release:

- [ ] Update version in `pubspec.yaml`
- [ ] Test application locally
- [ ] Update `CHANGELOG.md` (optional)
- [ ] Commit all changes
- [ ] Create git tag with version number
- [ ] Push tag to GitHub
- [ ] Wait for GitHub Actions to complete
- [ ] Verify release files are uploaded
- [ ] Test downloaded packages
- [ ] Announce release to users

## Version Numbering

Follow semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (e.g., `1.0.0` → `2.0.0`)
- **MINOR**: New features (e.g., `1.0.0` → `1.1.0`)
- **PATCH**: Bug fixes (e.g., `1.0.0` → `1.0.1`)

Examples:
```bash
# Bug fix release
git tag v1.0.1

# New feature release
git tag v1.1.0

# Major version release
git tag v2.0.0
```

## Troubleshooting

### Build Fails on GitHub Actions

**Check logs:**
1. Go to Actions tab
2. Click failed workflow
3. Expand failed step
4. Read error messages

**Common issues:**
- Missing dependencies in `pubspec.yaml`
- Syntax errors in code
- Flutter version incompatibility

**Fix:**
```bash
# Fix the issue locally
git add .
git commit -m "Fix build error"
git push origin main

# Re-tag (delete old tag first)
git tag -d v1.1.0
git push origin :refs/tags/v1.1.0
git tag v1.1.0
git push origin v1.1.0
```

### Release Not Created

Ensure:
- Tag name starts with `v` (e.g., `v1.0.0`)
- Tag is pushed to GitHub: `git push origin v1.0.0`
- GitHub Actions has permissions (check repository settings)

### Users Not Getting Updates

Verify:
1. Update URL is set in code
2. Latest release is published on GitHub
3. Release assets are uploaded
4. User has internet connection

## GitHub Repository Settings

### Enable GitHub Actions:
1. Go to repository settings
2. Navigate to **Actions** → **General**
3. Ensure **Allow all actions** is selected
4. Save changes

### Permissions for GITHUB_TOKEN:
1. Go to repository settings
2. Navigate to **Actions** → **General**
3. Under **Workflow permissions**:
   - Select **Read and write permissions**
   - Check **Allow GitHub Actions to create and approve pull requests**
4. Save changes

## Quick Reference

```bash
# Complete release workflow
cd /home/cipher/Documents/Projects/Records

# Update version
nano pubspec.yaml  # Change version number

# Commit and tag
git add .
git commit -m "Release v1.1.0"
git tag v1.1.0
git push origin main
git push origin v1.1.0

# Wait for builds, then check:
# https://github.com/kinetiq-labs/records/releases
```

## Support

For issues with:
- **GitHub Actions**: Check workflow logs
- **Build failures**: Review error messages in Actions tab
- **Release process**: Refer to this guide

---

**Next Steps:**
1. Push your code to GitHub: `git push origin main`
2. Create first release: `git tag v1.0.0 && git push origin v1.0.0`
3. Monitor Actions tab for build progress
4. Download and test release packages
