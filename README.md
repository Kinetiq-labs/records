# Records - Flutter Desktop Application

A modern, cross-platform desktop application built with Flutter for managing and organizing records. This application provides a clean, intuitive interface for creating, editing, searching, and categorizing various types of records.

## Features

- ✨ **Modern UI**: Clean Material Design 3 interface optimized for desktop
- 🔍 **Search & Filter**: Powerful search functionality across all record fields
- 📁 **Categories**: Organize records with predefined or custom categories
- 💾 **Local Database**: SQLite database for reliable local data storage
- 🎨 **Responsive Design**: Adaptive layout that works on different screen sizes
- 🌙 **Theme Support**: Light and dark theme support (system-based)
- 🖥️ **Cross-Platform**: Runs on Windows, macOS, and Linux

## Screenshots

*Screenshots will be added after the application is built and running*

## Getting Started

### Prerequisites

- Flutter SDK (3.10.0 or higher)
- Dart SDK (3.0.0 or higher)
- Platform-specific requirements:
  - **Windows**: Visual Studio 2022 with C++ development tools
  - **macOS**: Xcode 14 or higher
  - **Linux**: GTK development libraries

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd records
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Enable desktop support** (if not already enabled)
   ```bash
   flutter config --enable-windows-desktop
   flutter config --enable-macos-desktop
   flutter config --enable-linux-desktop
   ```

4. **Run the application**
   ```bash
   # For Windows
   flutter run -d windows
   
   # For macOS
   flutter run -d macos
   
   # For Linux
   flutter run -d linux
   ```

### Building for Release

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/
│   └── record.dart          # Record data model
├── providers/
│   └── records_provider.dart # State management for records
├── screens/
│   └── home_screen.dart     # Main application screen
├── utils/
│   └── database_helper.dart # SQLite database operations
└── widgets/
    ├── add_record_dialog.dart    # Dialog for adding new records
    ├── custom_app_bar.dart       # Custom application bar
    ├── edit_record_dialog.dart   # Dialog for editing records
    └── record_card.dart          # Widget for displaying record cards
```

## Key Components

### Record Model
The `Record` class represents the core data structure with the following fields:
- `id`: Unique identifier (auto-generated)
- `title`: Record title
- `description`: Detailed description
- `category`: Organization category
- `createdAt`: Creation timestamp
- `updatedAt`: Last modification timestamp
- `metadata`: Optional additional data

### Database
- Uses SQLite with `sqflite_common_ffi` for desktop compatibility
- Automatic database initialization and migration support
- Indexed fields for optimized search performance

### State Management
- Uses Provider pattern for state management
- Reactive UI updates when data changes
- Error handling and loading states

## Usage

### Adding Records
1. Click the "Add Record" floating action button
2. Fill in the title, category, and description
3. Choose from predefined categories or create custom ones
4. Click "Save" to store the record

### Editing Records
1. Click on any record card to view details
2. Click "Edit" or use the menu button on the card
3. Modify the fields as needed
4. Click "Update" to save changes

### Searching Records
1. Use the search bar at the top of the screen
2. Search works across title, description, and category fields
3. Results update in real-time as you type

### Organizing Records
- Records are automatically sorted by last update time
- Use categories to group related records
- Filter by category using the category chips

## Dependencies

### Core Dependencies
- `flutter`: Flutter SDK
- `provider`: State management
- `sqflite_common_ffi`: SQLite database for desktop
- `path_provider`: File system path access

### Desktop-Specific Dependencies
- `window_manager`: Window management and configuration
- `bitsdojo_window`: Custom window controls and styling

### UI Dependencies
- `cupertino_icons`: iOS-style icons
- Material Design 3 components (built into Flutter)

## Configuration

### Window Settings
The application is configured with:
- Default size: 1200x800 pixels
- Minimum size: 800x600 pixels
- Centered on screen launch
- Custom title bar support

### Database Configuration
- Database file: `records.db`
- Location: Platform-specific application documents directory
- Automatic backup and migration support

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development Guidelines

### Code Style
- Follow Dart/Flutter style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent indentation (2 spaces)

### Testing
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Debugging
```bash
# Run in debug mode
flutter run -d <platform> --debug

# Enable verbose logging
flutter run -d <platform> --verbose
```

## Troubleshooting

### Common Issues

1. **Database initialization fails**
   - Ensure write permissions in the application directory
   - Check if SQLite FFI is properly initialized

2. **Window doesn't appear on Linux**
   - Install required GTK development libraries
   - Check display server compatibility

3. **Build fails on Windows**
   - Verify Visual Studio C++ tools are installed
   - Ensure Windows SDK is available

### Performance Tips
- The application is optimized for desktop use
- Large datasets (1000+ records) perform well with indexed search
- Consider pagination for extremely large datasets


## Acknowledgments

- Flutter team for the excellent desktop support
- Material Design team for the design system
- SQLite team for the reliable database engine

## Roadmap

### Planned Features
- [ ] Import/Export functionality (JSON, CSV)
- [ ] Advanced filtering and sorting options
- [ ] Record templates and quick actions
- [ ] Backup and sync capabilities
- [ ] Plugin system for extensibility
- [ ] Advanced search with operators
- [ ] Bulk operations (edit, delete multiple records)
- [ ] Data visualization and statistics
- [ ] Keyboard shortcuts and accessibility improvements

### Version History
- **v1.0.0**: Initial release with core functionality
  - Basic CRUD operations
  - Search and categorization
  - Cross-platform desktop support
  - Material Design 3 UI

---

For more information, bug reports, or feature requests, please visit the [GitHub repository](https://github.com/your-username/records).
