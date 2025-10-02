# Database Schema Documentation

## Overview

The Records application uses SQLite as its database engine with a comprehensive schema designed for user management, record storage, and advanced features like categorization, tagging, and archiving.

## Database Version: 2

## Tables

### 1. users
Stores user account information with authentication and preferences.

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  passwordHash TEXT NOT NULL,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  isActive INTEGER DEFAULT 1,
  preferences TEXT
);
```

**Columns:**
- `id`: Unique user identifier (Primary Key)
- `email`: User's email address (Unique, used for login)
- `passwordHash`: SHA-256 hashed password
- `firstName`: User's first name
- `lastName`: User's last name
- `createdAt`: Account creation timestamp (ISO 8601)
- `updatedAt`: Last profile update timestamp (ISO 8601)
- `isActive`: Account status (1 = active, 0 = deactivated)
- `preferences`: JSON string of user preferences

**Indexes:**
- `idx_users_email` on `email`
- `idx_users_active` on `isActive`

### 2. records
Stores user records with enhanced features like priority, tags, and archiving.

```sql
CREATE TABLE records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  metadata TEXT,
  tags TEXT,
  priority INTEGER DEFAULT 0,
  isArchived INTEGER DEFAULT 0,
  FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
);
```

**Columns:**
- `id`: Unique record identifier (Primary Key)
- `userId`: Reference to the owning user (Foreign Key)
- `title`: Record title
- `description`: Record description/content
- `category`: Record category for organization
- `createdAt`: Record creation timestamp (ISO 8601)
- `updatedAt`: Last modification timestamp (ISO 8601)
- `metadata`: JSON string for additional record data
- `tags`: Comma-separated list of tags
- `priority`: Priority level (0=Low, 1=Medium, 2=High, 3=Critical)
- `isArchived`: Archive status (1 = archived, 0 = active)

**Indexes:**
- `idx_records_category` on `category`
- `idx_records_title` on `title`
- `idx_records_user` on `userId`
- `idx_records_created` on `createdAt`
- `idx_records_updated` on `updatedAt`
- `idx_records_priority` on `priority`
- `idx_records_archived` on `isArchived`

### 3. categories
Stores category definitions with visual customization options.

```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  color TEXT,
  icon TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
```

**Columns:**
- `id`: Unique category identifier (Primary Key)
- `name`: Category name (Unique)
- `color`: Hex color code for UI display
- `icon`: Icon identifier for UI display
- `createdAt`: Category creation timestamp (ISO 8601)
- `updatedAt`: Last modification timestamp (ISO 8601)

**Indexes:**
- `idx_categories_name` on `name`

### 4. database_metadata
Stores database versioning and migration information.

```sql
CREATE TABLE database_metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
```

**Columns:**
- `key`: Metadata key (Primary Key)
- `value`: Metadata value
- `updatedAt`: Last update timestamp (ISO 8601)

**Standard Keys:**
- `version`: Database schema version
- `created_at`: Database creation timestamp

## Relationships

### User → Records (One-to-Many)
- Each user can have multiple records
- Records are deleted when user is deleted (CASCADE)
- Foreign key: `records.userId` → `users.id`

### Categories → Records (One-to-Many)
- Records reference categories by name
- Categories can be shared across users
- No foreign key constraint (flexible categorization)

## Data Types and Formats

### Timestamps
All timestamps are stored as TEXT in ISO 8601 format:
```
YYYY-MM-DDTHH:MM:SS.sssZ
```

### JSON Fields
- `users.preferences`: User settings and preferences
- `records.metadata`: Additional record data

### Tags
Stored as comma-separated values in `records.tags`:
```
"work,important,meeting"
```

### Priority Levels
Integer values with semantic meaning:
- `0`: Low priority
- `1`: Medium priority
- `2`: High priority
- `3`: Critical priority

## Database Operations

### User Management
```dart
// Create user
final userId = await DatabaseHelper.instance.createUser(user);

// Authenticate
final user = await DatabaseHelper.instance.authenticateUser(email, password);

// Update user
await DatabaseHelper.instance.updateUser(user);

// Change password
await DatabaseHelper.instance.updateUserPassword(userId, newPassword);
```

### Record Management
```dart
// Create record for user
final recordId = await DatabaseHelper.instance.insertRecordForUser(record, userId);

// Get user records
final records = await DatabaseHelper.instance.getRecordsForUser(userId);

// Search with filters
final results = await DatabaseHelper.instance.searchRecordsAdvanced(
  userId: userId,
  query: "search term",
  category: "Work",
  priority: 2,
);

// Archive/unarchive
await DatabaseHelper.instance.toggleRecordArchive(recordId);
```

### Statistics and Analytics
```dart
// Get database statistics
final stats = await DatabaseHelper.instance.getDatabaseStats();

// Export user data
final exportData = await DatabaseService.instance.exportUserData(userId);
```

## Migration Strategy

### Version 1 → Version 2
The database automatically migrates from version 1 to 2 with the following changes:

1. **Add users table** with authentication support
2. **Enhance records table** with:
   - `userId` column (Foreign Key)
   - `tags` column for tagging
   - `priority` column for prioritization
   - `isArchived` column for archiving
3. **Add categories table** for better organization
4. **Add database_metadata table** for versioning
5. **Create comprehensive indexes** for performance

### Future Migrations
The migration system supports incremental updates:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 3) {
    // Add new features for version 3
  }
  if (oldVersion < 4) {
    // Add new features for version 4
  }
}
```

## Performance Considerations

### Indexing Strategy
- **Primary indexes** on frequently queried columns
- **Composite indexes** for common query patterns
- **Partial indexes** for filtered queries (e.g., active records only)

### Query Optimization
- Use parameterized queries to prevent SQL injection
- Limit result sets with LIMIT clauses
- Use appropriate WHERE clauses to leverage indexes
- Consider EXPLAIN QUERY PLAN for complex queries

### Database Maintenance
```dart
// Vacuum database to reclaim space
await db.execute('VACUUM');

// Analyze tables for query optimization
await db.execute('ANALYZE');
```

## Security Features

### Password Security
- Passwords are hashed using SHA-256
- No plain text passwords stored
- Salt can be added for enhanced security

### Data Isolation
- User data is isolated by `userId`
- Foreign key constraints ensure data integrity
- Soft delete for users (deactivation)

### SQL Injection Prevention
- All queries use parameterized statements
- Input validation at application layer
- Prepared statements for repeated queries

## Backup and Export

### Data Export Format
```json
{
  "export_date": "2024-01-01T00:00:00.000Z",
  "database_version": 2,
  "users": [...],
  "records": [...],
  "categories": [...],
  "metadata": [...]
}
```

### Backup Strategy
1. **Full database export** to JSON
2. **User-specific exports** for data portability
3. **Incremental backups** based on `updatedAt` timestamps
4. **File system backups** of SQLite database file

## API Reference

### DatabaseHelper Methods
- `createUser(User user)` → `Future<int>`
- `authenticateUser(String email, String password)` → `Future<User?>`
- `insertRecordForUser(Record record, int userId)` → `Future<int>`
- `getRecordsForUser(int userId)` → `Future<List<Record>>`
- `searchRecordsAdvanced(...)` → `Future<List<Record>>`
- `exportData()` → `Future<Map<String, dynamic>>`
- `getDatabaseStats()` → `Future<Map<String, dynamic>>`

### DatabaseService Methods
- `initialize({bool createSampleData})` → `Future<void>`
- `createUser(...)` → `Future<User?>`
- `authenticateUser(String email, String password)` → `Future<User?>`
- `createRecord(...)` → `Future<Record?>`
- `searchRecords(...)` → `Future<List<Record>>`
- `exportUserData(int userId)` → `Future<Map<String, dynamic>>`
- `getDatabaseStatistics()` → `Future<Map<String, dynamic>>`

## Best Practices

### Development
1. **Use transactions** for multi-table operations
2. **Handle exceptions** gracefully with try-catch blocks
3. **Validate input** before database operations
4. **Use connection pooling** for concurrent access
5. **Test migrations** thoroughly before deployment

### Production
1. **Regular backups** of database file
2. **Monitor database size** and performance
3. **Implement logging** for database operations
4. **Use database encryption** for sensitive data
5. **Plan for scaling** with larger datasets

## Troubleshooting

### Common Issues
1. **Database locked**: Ensure proper connection management
2. **Migration failures**: Check schema compatibility
3. **Performance issues**: Analyze query plans and indexes
4. **Data corruption**: Implement integrity checks
5. **Storage limits**: Monitor database file size

### Debugging Tools
```dart
// Enable SQL logging
await db.execute('PRAGMA case_sensitive_like = ON');

// Check database integrity
final result = await db.rawQuery('PRAGMA integrity_check');

// Get database info
final info = await db.rawQuery('PRAGMA database_list');