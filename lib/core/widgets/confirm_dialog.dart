import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_effect.dart';
import '../audio/sound_service.dart';

/// A YES/NO confirmation backed by CatUIPaid's sleeping-cat dialog sprite
/// (75×46 native). The buttons are baked into the art, so instead of
/// drawing our own we lock the image's aspect ratio and lay two invisible
/// tap targets over the YES/NO regions at their known fractional position
/// in that source image. Resolves `true` for YES, `false` for NO/dismiss.
class ConfirmDialog extends ConsumerWidget {
  const ConfirmDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: AspectRatio(
          aspectRatio: 75 / 46,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/ui/confirm_dialog_cat.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  Positioned(
                    left: w * 0.12,
                    top: h * 0.62,
                    width: w * 0.33,
                    height: h * 0.28,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          unawaited(
                            ref
                                .read(soundServiceProvider)
                                .play(SoundEffect.uiTap),
                          );
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * 0.53,
                    top: h * 0.62,
                    width: w * 0.33,
                    height: h * 0.28,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          unawaited(
                            ref
                                .read(soundServiceProvider)
                                .play(SoundEffect.uiTapNegative),
                          );
                          Navigator.of(context).pop(false);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
