import 'package:flutter/material.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  const PressableScale({super.key, required this.child});
  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool down = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => down = true),
    onPointerUp: (_) => setState(() => down = false),
    onPointerCancel: (_) => setState(() => down = false),
    child: AnimatedSlide(
      // Neo-brutalist press: the card sinks toward its hard shadow.
      offset: down && !MediaQuery.disableAnimationsOf(context)
          ? const Offset(.006, .02)
          : Offset.zero,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        scale: down && !MediaQuery.disableAnimationsOf(context) ? .975 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    ),
  );
}
