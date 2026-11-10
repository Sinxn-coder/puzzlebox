import 'package:flutter/material.dart';

/// Visual weight of the app's outlines and shadows.
///
/// * [bold] — the signature neo-brutalist look: thick black outlines and hard
///   offset shadows.
/// * [soft] — thinner, translucent outlines and gentle blurred shadows for
///   players who find the heavy outlines tiring.
enum NeoStyle { bold, soft }

/// Single source of truth for outline and shadow styling.
///
/// Widgets call [Neo.border], [Neo.side] and [Neo.shadow] instead of building
/// black borders and offset shadows by hand, so the whole app can switch
/// between [NeoStyle.bold] and [NeoStyle.soft] from one setting.
abstract final class Neo {
  static NeoStyle style = NeoStyle.bold;
  static bool dark = false;

  static bool get isSoft => style == NeoStyle.soft;

  /// Outline colour for the active style.
  static Color get ink {
    if (!isSoft) return Colors.black;
    return dark ? const Color(0x33FFFFFF) : const Color(0x33000000);
  }

  /// Scales a bold outline width down for the soft style.
  static double width(double bold) =>
      isSoft ? (bold * .5).clamp(1.0, 1.3) : bold;

  static Border border([double bold = 2]) =>
      Border.all(color: ink, width: width(bold));

  static BorderSide side([double bold = 2]) =>
      BorderSide(color: ink, width: width(bold));

  /// Hard offset shadow (bold) or a soft drop shadow (soft).
  static List<BoxShadow> shadow([double dx = 3, double? dy]) {
    final y = dy ?? dx;
    if (isSoft) {
      return [
        BoxShadow(
          color: dark ? const Color(0x66000000) : const Color(0x1A0F172A),
          offset: Offset(0, y.abs() * .6 + 1),
          blurRadius: dx.abs() * 3 + 6,
        ),
      ];
    }
    return [
      BoxShadow(color: Colors.black, offset: Offset(dx, y), blurRadius: 0),
    ];
  }

  /// Forces every element in the tree to rebuild so widgets that read the
  /// static style above pick up a change, including const subtrees.
  static void rebuildAll() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    root.visitChildren(rebuild);
  }
}
