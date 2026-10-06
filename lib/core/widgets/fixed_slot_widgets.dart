import 'dart:ui';
import 'package:flutter/material.dart';

/// Fixed-height info slot with short fade AnimatedSwitcher.
/// Keeps content pinned without intrinsic height jumps or collapsing.
class FixedInfoSlot extends StatelessWidget {
  final double height;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FixedInfoSlot({
    super.key,
    required this.height,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: child,
        ),
      ),
    );
  }
}

/// Fixed-height action bar with fixed button slots.
/// Uses [Visibility] with [maintainSize: true] so buttons never shift
/// when neighbor actions (like Next or Hint) appear/disappear.
class FixedActionBar extends StatelessWidget {
  final double height;
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final EdgeInsetsGeometry padding;

  const FixedActionBar({
    super.key,
    this.height = 52,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: children,
      ),
    );
  }
}

/// Helper for reserving button positions inside [FixedActionBar]
/// without causing neighbor shifts when conditionally visible.
class FixedActionItem extends StatelessWidget {
  final bool visible;
  final Widget child;

  const FixedActionItem({
    super.key,
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: child,
    );
  }
}

/// Fixed status row for timers, move counters, and scores with tabular figures.
class FixedStatusRow extends StatelessWidget {
  final double height;
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final EdgeInsetsGeometry padding;

  const FixedStatusRow({
    super.key,
    this.height = 36,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: children,
      ),
    );
  }
}

/// Formats text with Tabular Figures to prevent width jitter on number updates.
class TabularText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const TabularText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    return Text(
      text,
      style: baseStyle.copyWith(
        fontFeatures: [
          ...?baseStyle.fontFeatures,
          const FontFeature.tabularFigures(),
        ],
      ),
    );
  }
}
