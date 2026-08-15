import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared card treatment for surfaces that need to read as "one system"
/// with Settings.
///
/// Light mode uses the pastel `panel_card.png` art as-is (it already looks
/// right). Dark mode reuses that *exact same* art rather than switching to
/// a plain code-drawn rounded-rect border (which read as generic "CSS"
/// chrome) — the trick is a [ColorFilter.matrix] that turns the art's own
/// brightness into transparency: the pale fill (bright) becomes nearly
/// invisible, letting a near-black-purple backdrop show through, while the
/// already-darker periwinkle border/rivets (relatively dim) stay opaque
/// and get recolored to that same periwinkle. So the *shape* — rivets,
/// scalloped top tab, rounded corners — is identical to light mode; only
/// the palette differs.
class ThemedCard extends StatelessWidget {
  const ThemedCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 18,
    this.width,
    this.useArtInLightMode = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? width;

  /// Opt out of the pixel-art background for surfaces that were never
  /// meant to carry it in light mode (e.g. Drink Moment's timer box, a
  /// plain rounded card, not a signboard) — dark mode still gets the
  /// shared border-art treatment regardless, for cross-screen cohesion.
  final bool useArtInLightMode;

  static const _cardArt = AssetImage('assets/ui/panel_card.png');
  // Nine-slice, both axes: only the middle band stretches, the tab (top)
  // and rounded/riveted corners (source is 94×84) stay proportioned
  // regardless of the card's actual size.
  static const _cardArtSlice = Rect.fromLTRB(14, 26, 80, 72);

  /// Recolors every opaque pixel to the periwinkle border blue
  /// (`#8CAAEE`, same as the pixel-art buttons), then derives a *new*
  /// alpha from the source pixel's own luminance and original alpha:
  /// `newA = 21.0*A - 25.5*luminance`. A fully-transparent source pixel
  /// always maps to alpha 0 (can't leak into the image's already-
  /// transparent corners); real content clears (or clamps) hard by
  /// luminance 210 and saturates by 200.
  ///
  /// That ramp is deliberately steep and pinned to the *empty* gap
  /// between the art's two pixel populations — border/rivets sit at
  /// luminance ~150-190, fill at ~215-250 — rather than spanning
  /// border-average to fill-average. A shallower ramp (this used to run
  /// border-average to fill-average, ~160 to ~230) put real fill-noise
  /// pixels partway up the ramp instead of past its end, so ordinary
  /// paper-texture variation in the source art — invisible in light mode
  /// against its own pastel fill — came out the other side as visible
  /// alpha variation, i.e. patchy/blotchy fill instead of solid. Pinning
  /// both populations fully inside their flat zones makes the fill a
  /// true solid color and the border a single flat blue, matching light
  /// mode's flat-pastel-fill look tonally even though the palette differs.
  static const _borderOnlyFilter = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 140,
    0, 0, 0, 0, 170,
    0, 0, 0, 0, 238,
    -7.6245, -14.9685, -2.907, 21.0, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark && useArtInLightMode) {
      return Container(
        width: width,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: _cardArt,
            centerSlice: _cardArtSlice,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          ),
        ),
        padding: padding,
        child: child,
      );
    }

    if (!isDark) {
      return Container(
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: colors.border),
        ),
        child: child,
      );
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: _borderOnlyFilter,
              child: Image(
                image: _cardArt,
                centerSlice: _cardArtSlice,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
