import 'package:flutter/material.dart';

/// A full-screen page that slides up from the bottom, like a modal sheet,
/// instead of the platform-default horizontal push — used for Drink Moment
/// so it enters the same way Settings does, rather than feeling like a
/// different navigation metaphor mid-app.
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  SlideUpRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        );
}
