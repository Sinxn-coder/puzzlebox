import 'package:flutter/material.dart';
import 'package:puzzlebox/core/theme/neo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/settings_provider.dart';
import '../core/services/privacy_notice.dart';
import '../core/theme/app_theme.dart';

class PrivacyNoticeScreen extends ConsumerWidget {
  const PrivacyNoticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final accent = AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'Privacy & Data',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Container(
            height: 2.5,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // Neo badge & Title card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Neo.border(2.5),
                boxShadow: Neo.shadow(3.5),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(16),
                      border: Neo.border(2.5),
                      boxShadow: Neo.shadow(2.5),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Data Stays Yours',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '100% offline • No tracking • No accounts',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notice Content Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Neo.border(2.5),
                boxShadow: Neo.shadow(3.5),
              ),
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                privacyNotice,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
