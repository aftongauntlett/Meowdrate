import 'package:flutter/material.dart';

/// A button backed by a real bordered pill sprite (from the "Pastel" kit in
/// UI Bundle.zip) instead of a programmatic BoxDecoration — this is what
/// actually reads as "game button" rather than "website button with rounded
/// corners." Unlike the first version of this widget, the source pill is
/// already the color we want (a saturated periwinkle blue) — an earlier
/// attempt tinted a pale neutral pill via BlendMode.modulate to hit our
/// theme color, which is what made it look washed-out/wrong. This pill
/// doesn't shift with light/dark theme, same as its reference art (Focus
/// Friend's buttons don't repaint for system dark mode either) — it's a
/// fixed piece of game art, not a themed UI control.
class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.muted = false,
    this.height = 52,
  });

  final VoidCallback? onPressed;
  final Widget child;

  /// Dims the whole button (image + content) — used for a de-emphasized
  /// but still-tappable state (e.g. the Appearance toggle's unselected
  /// chips), as opposed to [onPressed] being null, which means "can't be
  /// tapped at all." Both end up looking the same (dimmed); the meaningful
  /// difference is whether `onTap` fires.
  final bool muted;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dim = muted || onPressed == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(height / 2),
        child: Opacity(
          opacity: dim ? 0.55 : 1.0,
          child: Container(
            height: height,
            alignment: Alignment.center,
            // Without this, a content-sized button (e.g. the Appearance
            // chips, which don't get a fixed/full width from their parent)
            // shrink-wraps the pill tight to its text with zero breathing
            // room, so labels touch the rounded edges.
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/ui/btn_pill_blue.png'),
                // Nine-slice: only the flat middle stretches, the rounded
                // end-caps (source is 55×22) stay proportioned at any width.
                centerSlice: Rect.fromLTRB(10, 0, 45, 22),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                shadows: [Shadow(color: Color(0x66000000), offset: Offset(0, 1))],
              ),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
