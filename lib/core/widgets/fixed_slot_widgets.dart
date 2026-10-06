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

/// Fixed-size board transition widget that seamlessly crossfades between puzzles.
/// Stack layout guarantees both incoming and outgoing widgets occupy the exact same
/// bounds with zero blank frames or opacity dip between puzzles.
class SmoothBoardTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final String? keyId;

  const SmoothBoardTransition({
    super.key,
    required this.child,
    this.keyId,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: keyId != null ? KeyedSubtree(key: ValueKey(keyId), child: child) : child,
    );
  }
}

/// Thin 2.5px generation progress bar that never shifts layout whether active or hidden.
class ThinGeneratingBar extends StatelessWidget {
  final bool isGenerating;
  const ThinGeneratingBar({super.key, required this.isGenerating});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2.5,
      child: isGenerating
          ? const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
            )
          : const SizedBox.shrink(),
    );
  }
}
