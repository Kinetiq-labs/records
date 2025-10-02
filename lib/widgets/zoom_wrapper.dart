import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/zoom_provider.dart';

class ZoomWrapper extends StatefulWidget {
  final Widget child;

  const ZoomWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ZoomWrapper> createState() => _ZoomWrapperState();
}

class _ZoomWrapperState extends State<ZoomWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ZoomProvider>(
      builder: (context, zoomProvider, child) {
        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              // Check if Ctrl key is pressed
              final bool isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

              if (isCtrlPressed) {
                // Prevent default scroll behavior when zooming
                if (pointerSignal.scrollDelta.dy > 0) {
                  // Scroll down = zoom out
                  zoomProvider.zoomOut();
                } else if (pointerSignal.scrollDelta.dy < 0) {
                  // Scroll up = zoom in
                  zoomProvider.zoomIn();
                }
              }
            }
          },
          child: Transform.scale(
            scale: zoomProvider.zoomLevel,
            alignment: Alignment.center,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// A keyboard shortcuts widget for zoom functionality
class ZoomKeyboardShortcuts extends StatelessWidget {
  final Widget child;

  const ZoomKeyboardShortcuts({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ZoomProvider>(
      builder: (context, zoomProvider, child) {
        return Shortcuts(
          shortcuts: {
            // Ctrl + Plus for zoom in
            const SingleActivator(
              LogicalKeyboardKey.equal,
              control: true,
            ): ZoomInIntent(),
            const SingleActivator(
              LogicalKeyboardKey.add,
              control: true,
            ): ZoomInIntent(),
            const SingleActivator(
              LogicalKeyboardKey.numpadAdd,
              control: true,
            ): ZoomInIntent(),

            // Ctrl + Minus for zoom out
            const SingleActivator(
              LogicalKeyboardKey.minus,
              control: true,
            ): ZoomOutIntent(),
            const SingleActivator(
              LogicalKeyboardKey.numpadSubtract,
              control: true,
            ): ZoomOutIntent(),

            // Ctrl + 0 for reset zoom
            const SingleActivator(
              LogicalKeyboardKey.digit0,
              control: true,
            ): ZoomResetIntent(),
            const SingleActivator(
              LogicalKeyboardKey.numpad0,
              control: true,
            ): ZoomResetIntent(),
          },
          child: Actions(
            actions: {
              ZoomInIntent: CallbackAction<ZoomInIntent>(
                onInvoke: (intent) => zoomProvider.zoomIn(),
              ),
              ZoomOutIntent: CallbackAction<ZoomOutIntent>(
                onInvoke: (intent) => zoomProvider.zoomOut(),
              ),
              ZoomResetIntent: CallbackAction<ZoomResetIntent>(
                onInvoke: (intent) => zoomProvider.resetZoom(),
              ),
            },
            child: this.child,
          ),
        );
      },
    );
  }
}

// Intent classes for keyboard shortcuts
class ZoomInIntent extends Intent {}
class ZoomOutIntent extends Intent {}
class ZoomResetIntent extends Intent {}