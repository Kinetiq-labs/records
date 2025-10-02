import 'package:flutter/material.dart';

/// Responsive utilities for handling different screen sizes
class ResponsiveUtils {
  // Breakpoints for different screen sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  static const double largeDesktopBreakpoint = 1920;

  /// Get screen type based on width
  static ScreenType getScreenType(double width) {
    if (width < mobileBreakpoint) return ScreenType.mobile;
    if (width < tabletBreakpoint) return ScreenType.tablet;
    if (width < desktopBreakpoint) return ScreenType.desktop;
    if (width < largeDesktopBreakpoint) return ScreenType.largeDesktop;
    return ScreenType.ultraWide;
  }

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if screen is desktop or larger
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Check if screen is large desktop or ultra-wide
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(12);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(16);
    } else if (width < desktopBreakpoint) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Get responsive margin based on screen size
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(8);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(12);
    } else if (width < desktopBreakpoint) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return baseFontSize * 0.9;
    } else if (width < tabletBreakpoint) {
      return baseFontSize;
    } else if (width < desktopBreakpoint) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize * 1.2;
    }
  }

  /// Get responsive container width with max constraints
  static double getResponsiveContainerWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileBreakpoint) {
      return screenWidth - 24; // Full width with padding
    } else if (screenWidth < tabletBreakpoint) {
      return screenWidth - 40; // Tablet width with padding
    } else if (screenWidth < desktopBreakpoint) {
      return 900; // Max width for desktop
    } else if (screenWidth < largeDesktopBreakpoint) {
      return 1200; // Max width for large desktop
    } else {
      return 1400; // Max width for ultra-wide
    }
  }

  /// Get number of columns for grid layouts
  static int getResponsiveColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return 1;
    } else if (width < tabletBreakpoint) {
      return 2;
    } else if (width < desktopBreakpoint) {
      return 3;
    } else if (width < largeDesktopBreakpoint) {
      return 4;
    } else {
      return 5;
    }
  }

  /// Get responsive card dimensions
  static Size getResponsiveCardSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return const Size(double.infinity, 120);
    } else if (width < tabletBreakpoint) {
      return const Size(400, 140);
    } else if (width < desktopBreakpoint) {
      return const Size(450, 160);
    } else {
      return const Size(500, 180);
    }
  }

  /// Get responsive table row height
  static double getResponsiveTableRowHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return 60;
    } else if (width < tabletBreakpoint) {
      return 70;
    } else {
      return 80;
    }
  }

  /// Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return kToolbarHeight;
    } else if (width < tabletBreakpoint) {
      return kToolbarHeight + 10;
    } else {
      return kToolbarHeight + 20;
    }
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return baseSpacing * 0.8;
    } else if (width < tabletBreakpoint) {
      return baseSpacing;
    } else if (width < desktopBreakpoint) {
      return baseSpacing * 1.2;
    } else {
      return baseSpacing * 1.4;
    }
  }
}

/// Screen type enumeration
enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
  ultraWide,
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(MediaQuery.of(context).size.width);
    return builder(context, screenType);
  }
}

/// Responsive layout widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType) {
        switch (screenType) {
          case ScreenType.mobile:
            return mobile;
          case ScreenType.tablet:
            return tablet ?? mobile;
          case ScreenType.desktop:
            return desktop ?? tablet ?? mobile;
          case ScreenType.largeDesktop:
          case ScreenType.ultraWide:
            return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Responsive container with max width constraints
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BoxDecoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: ResponsiveUtils.getResponsiveContainerWidth(context),
        padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
        margin: margin ?? ResponsiveUtils.getResponsiveMargin(context),
        color: color,
        decoration: decoration,
        child: child,
      ),
    );
  }
}

/// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double baseFontSize;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.baseFontSize = 14.0,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = ResponsiveUtils.getResponsiveFontSize(context, baseFontSize);

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: responsiveFontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}