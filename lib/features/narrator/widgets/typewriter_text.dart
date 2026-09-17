import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_effect.dart';
import '../../../core/audio/sound_service.dart';
import '../providers/narrator_providers.dart';

/// Reveals [text] one character at a time, like the narrator is speaking it
/// live, with a soft blip every few characters — the Stardew/Inscryption/
/// Graveyard Keeper dialogue-box feel. Tap anywhere on it to skip straight
/// to the full line.
///
/// The full [text] is always laid out (via two [TextSpan]s, one transparent)
/// rather than growing a substring, so the surrounding scene never reflows
/// or jumps as characters reveal.
class TypewriterText extends ConsumerStatefulWidget {
  const TypewriterText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.charDuration = const Duration(milliseconds: 24),
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// How long each revealed character stays on screen for before the next
  /// one appears. Punctuation holds for a few multiples of this to give the
  /// line a breath, matching how those games pause on periods/commas.
  final Duration charDuration;

  @override
  ConsumerState<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends ConsumerState<TypewriterText> {
  int _visibleChars = 0;
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = null;
    setState(() => _visibleChars = 0);
    if (widget.text.isEmpty) return;
    // A line change while DrinkMomentScreen is up (e.g. the drink being
    // logged under this still-mounted scene) must not restart the blips —
    // that's the race that can mute the song. Resume from [_resume] once
    // the overlay is gone.
    if (_paused || ref.read(narratorPlaybackPausedProvider)) {
      _paused = true;
      return;
    }
    _timer = Timer.periodic(widget.charDuration, (_) => _revealNextChar());
  }

  void _pause() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  void _resume() {
    _paused = false;
    if (!mounted || widget.text.isEmpty) return;
    if (_visibleChars >= widget.text.length) return;
    if (_timer != null) return;
    _timer = Timer.periodic(widget.charDuration, (_) => _revealNextChar());
  }

  void _revealNextChar() {
    if (_paused || ref.read(narratorPlaybackPausedProvider)) {
      _pause();
      return;
    }
    if (_visibleChars >= widget.text.length) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    final revealedChar = widget.text[_visibleChars];
    setState(() => _visibleChars++);

    // A blip every few printable characters, not every one — one-per-char
    // overlaps into a buzz at this speed. Skip on whitespace so the blips
    // roughly track syllables instead of a fixed cadence.
    if (revealedChar.trim().isNotEmpty && _visibleChars % 3 == 0) {
      ref.read(soundServiceProvider).play(SoundEffect.narratorBlip);
    }

    // Give punctuation a beat of silence, like a spoken pause.
    if ('.,!?'.contains(revealedChar)) {
      _timer?.cancel();
      _timer = Timer(widget.charDuration * 6, () {
        if (_paused) return;
        _timer = Timer.periodic(widget.charDuration, (_) => _revealNextChar());
      });
    }
  }

  void _skipToEnd() {
    unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTap));
    _timer?.cancel();
    setState(() => _visibleChars = widget.text.length);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(narratorPlaybackPausedProvider, (previous, next) {
      if (next) {
        _pause();
      } else {
        _resume();
      }
    });

    final revealed = widget.text.substring(0, _visibleChars);
    final hidden = widget.text.substring(_visibleChars);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skipToEnd,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: revealed, style: widget.style),
            TextSpan(
              text: hidden,
              style: (widget.style ?? const TextStyle()).copyWith(
                color: Colors.transparent,
              ),
            ),
          ],
        ),
        textAlign: widget.textAlign,
      ),
    );
  }
}
