import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/neo.dart';

/// Shown in Daily mode once today's puzzle is solved: a countdown to the next
/// daily and a quick way into Unlimited.
class DailyDoneBanner extends StatefulWidget {
  final VoidCallback onPlayUnlimited;
  const DailyDoneBanner({super.key, required this.onPlayUnlimited});

  @override
  State<DailyDoneBanner> createState() => _DailyDoneBannerState();
}

class _DailyDoneBannerState extends State<DailyDoneBanner> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  static String untilTomorrow() {
    final now = DateTime.now();
    final left = DateTime(now.year, now.month, now.day + 1).difference(now);
    final h = left.inHours;
    final m = left.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80),
          borderRadius: BorderRadius.circular(14),
          border: Neo.border(2),
          boxShadow: Neo.shadow(2),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Today's done ✓ · next in ${untilTomorrow()}",
                maxLines: 2,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: Neo.side(1.5),
                ),
              ),
              onPressed: widget.onPlayUnlimited,
              child: const Text(
                'Play Unlimited',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
