import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final bool showHomeButton;
  final VoidCallback? onHomePressed;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.appBar,
    this.showHomeButton = false,
    this.onHomePressed,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: appBar ??
              AppBar(
                title: ResponsiveText(
                  title,
                  baseFontSize: _getTitleFontSize(screenType),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                actions: actions,
                centerTitle: true,
                toolbarHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
              ),
          body: ResponsiveContainer(
            child: body,
          ),
          floatingActionButton: floatingActionButton,
          drawer: drawer,
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }

  double _getTitleFontSize(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 18.0;
      case ScreenType.tablet:
        return 20.0;
      case ScreenType.desktop:
        return 22.0;
      case ScreenType.largeDesktop:
      case ScreenType.ultraWide:
        return 24.0;
    }
  }
}