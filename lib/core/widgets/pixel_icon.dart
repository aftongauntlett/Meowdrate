import 'package:flutter/material.dart';

/// A bare CatUIPaid icon glyph (no button chrome baked in — see
/// assets/ui/README.md), recolored via BlendMode.srcIn so it behaves like a
/// normal monochrome Icon: legible against any background, adapts with the
/// theme, instead of carrying its own fixed black+pink art.
///
/// Most call sites use this glyph decoratively next to a text label that
/// already carries the accessible name (e.g. the check icon beside "I
/// Meowdrated!"), so it's excluded from the semantics tree by default to
/// avoid a redundant/empty announcement. Pass [semanticLabel] for the rarer
/// case where the icon is the only content of its own tap target.
class PixelIcon extends StatelessWidget {
  const PixelIcon(
    this.assetPath, {
    super.key,
    required this.color,
    this.size = 24,
    this.semanticLabel,
  });

  final String assetPath;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      // The source glyphs are tiny (~13x18px, cropped straight off the
      // sprite sheet) — without an explicit fit, Image renders them at
      // that native pixel size inside the box instead of scaling up,
      // which is why these were showing as barely-visible specks rather
      // than actual plus/check/x/minus shapes.
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
