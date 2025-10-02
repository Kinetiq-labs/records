# Supabase Integration Setup Guide

This guide explains how to set up Supabase integration for your Records app to enable data synchronization and backup functionality.

## Overview

The Supabase integration provides:
- **Offline-first operation**: Your app works fully offline
- **Data backup**: Upload local data to Supabase cloud storage
- **Data restore**: Download data from cloud to local device
- **Full synchronization**: Bidirectional sync between local and cloud
- **Multi-tenant support**: Each user's data is isolated

## Prerequisites

1. A Supabase account (sign up at https://supabase.com)
2. Flutter development environment
3. Your Records app already installed and running

## Step 1: Create Supabase Project

1. Go to https://supabase.com and sign in
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - **Name**: "Records App" (or your preferred name)
   - **Database Password**: Create a strong password
   - **Region**: Choose closest to your users
5. Click "Create new project"
6. Wait for the project to be provisioned (takes ~2 minutes)

## Step 2: Set Up Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **New query**
3. Copy and paste the entire contents of `supabase_schema.sql` (located in your project root)
4. Click **Run** to execute the schema

This will create:
- All necessary tables matching your local database structure
- Row Level Security (RLS) policies for data isolation
- Indexes for optimal performance
- Automatic timestamp triggers

## Step 3: Get Your Supabase Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy these values:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **Public anon key** (starts with `eyJ...`)

## Step 4: Configure Your App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
  // ... rest of the file
}
```

3. Save the file

## Step 5: Install Dependencies

Run the following command in your project directory:

```bash
flutter pub get
```

This will install the new Supabase dependencies.

## Step 6: Initialize Supabase in Your App

Add the Supabase initialization to your main.dart file:

```dart
import 'package:flutter/material.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(MyApp());
}
```

## Step 7: Add Sync UI to Your App

### Option 1: Add Sync Status Widget to Home Screen

Add this to your home screen or main app bar:

```dart
import 'widgets/sync_status_widget.dart';

// In your AppBar or anywhere in your UI:
SyncStatusWidget(
  showLabel: true,
  showProgress: true,
)
```

### Option 2: Add Quick Sync Button

Add a quick sync popup menu:

```dart
import 'widgets/sync_status_widget.dart';

// In your AppBar actions or floating action button:
QuickSyncButton(
  tenantId: 'your_tenant_id', // Use your app's tenant ID
)
```

### Option 3: Add Full Sync Settings Screen

Add a menu item or button to navigate to sync settings:

```dart
import 'screens/sync_settings_screen.dart';

// Navigate to sync settings:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SyncSettingsScreen()),
)
```

## How to Use Sync Features

### First Time Setup

1. Open your app
2. Navigate to sync settings (or tap the sync status widget)
3. Tap "Connect to Sync Service"
4. The app will authenticate anonymously with Supabase

### Backup Your Data

1. Ensure you're connected to the internet
2. Go to sync settings or use the quick sync button
3. Choose "Backup Data"
4. Your local data will be uploaded to Supabase

### Restore Data

1. On a new device or after reinstalling the app
2. Connect to sync service
3. Choose "Restore Data"
4. Your data will be downloaded from Supabase

### Full Sync

1. Choose "Full Sync" to backup and restore in one operation
2. This ensures your local and cloud data are identical

## Data Security

- **Row Level Security**: Each user can only access their own data
- **Anonymous Authentication**: No personal information required
- **Encrypted Transit**: All data is encrypted in transit
- **Isolated Tenants**: Multi-tenant architecture ensures data separation

## Troubleshooting

### Connection Issues

- Verify your Supabase URL and anon key are correct
- Check your internet connection
- Ensure Supabase project is active (not paused)

### Sync Failures

- Check the sync status for error messages
- Verify your local database is working properly
- Try connecting to sync service again

### Performance

- Large datasets may take time to sync
- Use incremental sync for better performance
- Consider syncing during off-peak hours

## Database Schema Details

The Supabase schema includes these main tables:

| Table | Purpose |
|-------|---------|
| `business_years` | Business year periods |
| `business_months` | Monthly periods within years |
| `business_days` | Daily periods within months |
| `khata_entries` | Main transaction records |
| `customers` | Customer information |
| `sync_metadata` | Sync tracking information |

All tables include:
- UUID primary keys for Supabase
- `user_id` foreign key linking to authenticated user
- `tenant_id` for multi-tenant support
- Automatic timestamps (`created_at`, `updated_at`)
- Sync status tracking

## API Limits

Supabase free tier includes:
- Up to 500MB database storage
- Up to 2GB bandwidth per month
- Up to 50,000 monthly active users

For larger usage, consider upgrading to Supabase Pro.

## Support

If you encounter issues:
1. Check the sync status for error messages
2. Review the Supabase dashboard for any alerts
3. Ensure your app version supports sync features
4. Contact support with specific error messages

## Security Best Practices

1. **Never commit credentials**: Keep your Supabase keys secure
2. **Use environment variables**: For production deployments
3. **Monitor usage**: Check Supabase dashboard regularly
4. **Enable RLS**: Row Level Security is enabled by default
5. **Regular backups**: Don't rely solely on cloud sync for backups

---

**Note**: This integration requires an active internet connection for sync operations. The app continues to work offline, and sync will occur when connectivity is restored.