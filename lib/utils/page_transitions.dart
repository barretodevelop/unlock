// lib/utils/page_transitions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PageTransitions {
  static const Duration _defaultDuration = Duration(milliseconds: 300);
  static const Curve _defaultCurve = Curves.easeInOut;

  // Fade transition - Para splash e login
  static Page<void> fadeTransition({
    required LocalKey key,
    required Widget child,
    Duration duration = _defaultDuration,
    Curve curve = _defaultCurve,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // Slide from right - Para navegação para frente (home)
  static Page<void> slideFromRight({
    required LocalKey key,
    required Widget child,
    Duration duration = _defaultDuration,
    Curve curve = _defaultCurve,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;

        final slideTween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        final slideAnimation = slideTween.animate(curvedAnimation);

        // Fade out para a página anterior
        final fadeOutAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(parent: secondaryAnimation, curve: curve));

        return Stack(
          children: [
            // Página anterior com fade out
            if (secondaryAnimation.value > 0)
              FadeTransition(
                opacity: fadeOutAnimation,
                child: Container(), // Placeholder para página anterior
              ),
            // Nova página com slide
            SlideTransition(
              position: slideAnimation,
              child: FadeTransition(opacity: animation, child: child),
            ),
          ],
        );
      },
    );
  }

  // Slide from left - Para navegação para trás
  static Page<void> slideFromLeft({
    required LocalKey key,
    required Widget child,
    Duration duration = _defaultDuration,
    Curve curve = _defaultCurve,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;

        final slideAnimation = Tween(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  // Slide from bottom - Para modais e perfil
  static Page<void> slideFromBottom({
    required LocalKey key,
    required Widget child,
    Duration duration = _defaultDuration,
    Curve curve = _defaultCurve,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;

        final slideAnimation = Tween(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  // Scale transition - Para efeitos especiais
  static Page<void> scaleTransition({
    required LocalKey key,
    required Widget child,
    Duration duration = _defaultDuration,
    Curve curve = _defaultCurve,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  // Rotation transition - Para efeitos especiais
  static Page<void> rotationTransition({
    required LocalKey key,
    required Widget child,
    Duration duration = _defaultDuration,
    Curve curve = _defaultCurve,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final rotationAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return RotationTransition(
          turns: rotationAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  // Custom combined transition
  static Page<void> customTransition({
    required LocalKey key,
    required Widget child,
    Duration duration = _defaultDuration,
    Curve curve = _defaultCurve,
    Offset? slideBegin,
    double? scaleBegin,
    double? rotationBegin,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        Widget result = child;

        // Apply fade
        result = FadeTransition(opacity: curvedAnimation, child: result);

        // Apply slide if specified
        if (slideBegin != null) {
          final slideAnimation = Tween(
            begin: slideBegin,
            end: Offset.zero,
          ).animate(curvedAnimation);

          result = SlideTransition(position: slideAnimation, child: result);
        }

        // Apply scale if specified
        if (scaleBegin != null) {
          final scaleAnimation = Tween<double>(
            begin: scaleBegin,
            end: 1.0,
          ).animate(curvedAnimation);

          result = ScaleTransition(scale: scaleAnimation, child: result);
        }

        // Apply rotation if specified
        if (rotationBegin != null) {
          final rotationAnimation = Tween<double>(
            begin: rotationBegin,
            end: 1.0,
          ).animate(curvedAnimation);

          result = RotationTransition(turns: rotationAnimation, child: result);
        }

        return result;
      },
    );
  }
}
