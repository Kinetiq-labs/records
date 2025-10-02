import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Responsive AppBar that adapts to different screen sizes
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool? centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool showHomeButton;
  final VoidCallback? onHomePressed;

  const ResponsiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showHomeButton = false,
    this.onHomePressed,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType) {
        return AppBar(
          title: _buildTitle(context, screenType),
          actions: _buildActions(context, screenType),
          leading: _buildLeading(context, screenType),
          centerTitle: centerTitle ?? true,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: elevation,
          toolbarHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context, ScreenType screenType) {
    double baseFontSize;
    switch (screenType) {
      case ScreenType.mobile:
        baseFontSize = 18.0;
        break;
      case ScreenType.tablet:
        baseFontSize = 20.0;
        break;
      case ScreenType.desktop:
        baseFontSize = 22.0;
        break;
      case ScreenType.largeDesktop:
      case ScreenType.ultraWide:
        baseFontSize = 24.0;
        break;
    }

    return ResponsiveText(
      title,
      baseFontSize: baseFontSize,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: foregroundColor,
      ),
    );
  }

  List<Widget>? _buildActions(BuildContext context, ScreenType screenType) {
    if (actions == null && !showHomeButton) return null;

    final List<Widget> actionList = [];

    if (showHomeButton && onHomePressed != null) {
      actionList.add(
        IconButton(
          onPressed: onHomePressed,
          icon: Icon(
            Icons.home,
            size: _getIconSize(screenType),
            color: foregroundColor,
          ),
          tooltip: 'Home',
        ),
      );
    }

    if (actions != null) {
      actionList.addAll(actions!);
    }

    return actionList.isEmpty ? null : actionList;
  }

  Widget? _buildLeading(BuildContext context, ScreenType screenType) {
    if (leading != null) return leading;

    // Auto-generate back button with responsive size
    if (ModalRoute.of(context)?.canPop == true) {
      return IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back,
          size: _getIconSize(screenType),
          color: foregroundColor,
        ),
      );
    }

    return null;
  }

  double _getIconSize(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 20.0;
      case ScreenType.tablet:
        return 22.0;
      case ScreenType.desktop:
        return 24.0;
      case ScreenType.largeDesktop:
      case ScreenType.ultraWide:
        return 26.0;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(
        kToolbarHeight + 20, // Default responsive height
      );
}

/// Responsive SliverAppBar for scrollable layouts
class ResponsiveSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool? centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool pinned;
  final bool floating;
  final double? expandedHeight;
  final Widget? flexibleSpace;

  const ResponsiveSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType) {
        return SliverAppBar(
          title: _buildTitle(context, screenType),
          actions: actions,
          leading: leading,
          centerTitle: centerTitle ?? true,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: elevation,
          pinned: pinned,
          floating: floating,
          expandedHeight: expandedHeight,
          flexibleSpace: flexibleSpace,
          toolbarHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context, ScreenType screenType) {
    double baseFontSize;
    switch (screenType) {
      case ScreenType.mobile:
        baseFontSize = 18.0;
        break;
      case ScreenType.tablet:
        baseFontSize = 20.0;
        break;
      case ScreenType.desktop:
        baseFontSize = 22.0;
        break;
      case ScreenType.largeDesktop:
      case ScreenType.ultraWide:
        baseFontSize = 24.0;
        break;
    }

    return ResponsiveText(
      title,
      baseFontSize: baseFontSize,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: foregroundColor,
      ),
    );
  }
}