import 'package:flutter/material.dart';

PageRouteBuilder<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: child,
    ),
  );
}

PageRouteBuilder<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      final offset = Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(anim);
      return SlideTransition(
        position: offset,
        child: child,
      );
    },
  );
}
