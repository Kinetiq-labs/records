import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/zoom_provider.dart';

class ZoomIndicator extends StatelessWidget {
  final bool showAlways;
  final Duration fadeOutDuration;

  const ZoomIndicator({
    super.key,
    this.showAlways = false,
    this.fadeOutDuration = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ZoomProvider>(
      builder: (context, zoomProvider, child) {
        // Only show indicator if zoom level is not at default (100%) or if showAlways is true
        if (!showAlways && zoomProvider.zoomLevel == 1.0) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.zoom_in,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  zoomProvider.zoomPercentage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A floating zoom control widget with buttons
class ZoomControls extends StatelessWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ZoomProvider>(
      builder: (context, zoomProvider, child) {
        return Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
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
              children: [
                IconButton(
                  onPressed: zoomProvider.zoomLevel < zoomProvider.maxZoomLevel
                      ? zoomProvider.zoomIn
                      : null,
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Zoom In (Ctrl + Scroll Up)',
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                Text(
                  zoomProvider.zoomPercentage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                IconButton(
                  onPressed: zoomProvider.zoomLevel > zoomProvider.minZoomLevel
                      ? zoomProvider.zoomOut
                      : null,
                  icon: const Icon(Icons.remove, size: 20),
                  tooltip: 'Zoom Out (Ctrl + Scroll Down)',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}