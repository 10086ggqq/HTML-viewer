import 'package:flutter/material.dart';

/// Chest-opening page transition: the new page scales up from 0.92 with a
/// fade, like opening a chest in Minecraft. Reversible without lag.
class ChestPageTransitionsBuilder extends PageTransitionsBuilder {
  const ChestPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.2, 0.0, 0.0, 1.0),
      reverseCurve: Curves.easeIn,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curved),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}
