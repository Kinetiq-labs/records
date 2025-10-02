# Quick Database Setup for Supabase

## Step 1: Access Supabase SQL Editor

1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Select your project: **Records App**
3. Click **SQL Editor** in the left sidebar
4. Click **New query**

## Step 2: Run the Schema Script

Copy and paste the **entire contents** of the `supabase_schema.sql` file into the SQL editor and click **Run**.

This will create:
- ✅ All necessary tables (business_years, business_months, business_days, khata_entries, customers, sync_metadata)
- ✅ Row Level Security policies for data protection
- ✅ Indexes for optimal performance
- ✅ Automatic timestamp triggers

## Step 3: Verify Setup

After running the script, you should see:
- **Tables** created in the Database → Tables section
- **No errors** in the SQL editor
- **Success message** confirming execution

## Step 4: Test Your App

1. Run your Flutter app: `flutter run`
2. Go to **Settings** in your app
3. Look for the **sync status widget** - it should show "Offline" initially
4. Tap the sync widget to open sync settings
5. Tap **"Connect to Sync Service"**
6. It should change to show "Online" status

## Troubleshooting

**If connection fails:**
- Check your internet connection
- Verify the Supabase URL and key are correct in `supabase_config.dart`
- Check the Flutter console for error messages

**If tables aren't created:**
- Make sure you copied the entire SQL script
- Check for error messages in the SQL editor
- Try running the script again

**If sync operations fail:**
- Ensure Row Level Security policies were created
- Check that all tables have the required columns
- Verify your project isn't paused in Supabase

## Quick Test Steps

Once everything is set up:

1. **Connect**: Tap sync widget → "Connect to Sync Service"
2. **Backup**: Choose "Backup Data" to upload your local data
3. **Verify**: Check Supabase dashboard → Database → Tables to see your data
4. **Restore**: Try "Restore Data" to download (won't overwrite existing data)

Your sync integration is now complete and ready to use!