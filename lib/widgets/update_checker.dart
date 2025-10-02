import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/update_provider.dart';
import 'update_notification_dialog.dart';

class UpdateChecker extends StatefulWidget {
  final Widget child;
  final bool enableAutoCheck;
  final Duration checkInterval;

  const UpdateChecker({
    super.key,
    required this.child,
    this.enableAutoCheck = true,
    this.checkInterval = const Duration(hours: 6),
  });

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  bool _hasShownUpdateDialog = false;

  @override
  void initState() {
    super.initState();

    // Initialize update checking after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUpdateChecking();
    });
  }

  void _initializeUpdateChecking() {
    final updateProvider = context.read<UpdateProvider>();

    // Initialize the provider
    updateProvider.initialize();

    // Listen to update provider changes
    updateProvider.addListener(_onUpdateStatusChanged);

    // Set up periodic checking if enabled
    if (widget.enableAutoCheck) {
      _setupPeriodicChecking();
    }
  }

  void _setupPeriodicChecking() {
    // Check for updates periodically
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _checkForUpdatesIfNeeded();
      }
    });

    // Set up recurring checks
    Stream.periodic(widget.checkInterval).listen((_) {
      if (mounted) {
        _checkForUpdatesIfNeeded();
      }
    });
  }

  Future<void> _checkForUpdatesIfNeeded() async {
    final updateProvider = context.read<UpdateProvider>();

    if (updateProvider.status == UpdateStatus.idle) {
      await updateProvider.checkForUpdates();
    }
  }

  void _onUpdateStatusChanged() {
    final updateProvider = context.read<UpdateProvider>();

    if (updateProvider.hasUpdate && !_hasShownUpdateDialog && mounted) {
      _hasShownUpdateDialog = true;
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
    final updateProvider = context.read<UpdateProvider>();

    showUpdateDialog(
      context,
      currentVersion: updateProvider.currentVersion ?? '1.0.0',
      latestVersion: updateProvider.latestVersion ?? '1.0.0',
      releaseNotes: updateProvider.releaseNotes ?? '',
      onUpdate: () async {
        await updateProvider.downloadAndInstallUpdate();
      },
      onLater: () async {
        await updateProvider.delayUpdate();
        setState(() {
          _hasShownUpdateDialog = false; // Allow showing again after delay
        });
      },
    );
  }

  @override
  void dispose() {
    final updateProvider = context.read<UpdateProvider>();
    updateProvider.removeListener(_onUpdateStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateProvider>(
      builder: (context, updateProvider, child) {
        return Stack(
          alignment: Alignment.topLeft,
          children: [
            widget.child,

            // Show update indicator in the corner if update is available
            if (updateProvider.hasUpdate && !_hasShownUpdateDialog)
              Positioned(
                top: 16,
                right: 16,
                child: _buildUpdateIndicator(updateProvider),
              ),

            // Show download progress if downloading
            if (updateProvider.status == UpdateStatus.downloading)
              _buildDownloadProgress(updateProvider),
          ],
        );
      },
    );
  }

  Widget _buildUpdateIndicator(UpdateProvider updateProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showUpdateDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.system_update,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Update Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadProgress(UpdateProvider updateProvider) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download, size: 20),
                const SizedBox(width: 8),
                Text(
                  updateProvider.status == UpdateStatus.downloading
                      ? 'Downloading Update...'
                      : 'Installing Update...',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '${(updateProvider.downloadProgress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: updateProvider.downloadProgress,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to wrap the main app with update checking functionality
class UpdateWrapper extends StatelessWidget {
  final Widget child;

  const UpdateWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UpdateProvider(),
      child: UpdateChecker(
        child: child,
      ),
    );
  }
}