import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_colors.dart';
import '../models/pet_mood.dart';

/// Renders the pet's current mood animation, plus any equipped accessory.
///
/// Looks for `assets/pet/<mood>.json` (a Lottie animation) and falls back to
/// a simple emoji placeholder if the file hasn't been added yet, so the app
/// is fully runnable before real character art/sprites are sourced. See
/// assets/pet/README.md for the expected filenames.
class PetView extends StatelessWidget {
  const PetView({
    super.key,
    required this.mood,
    this.accessoryEmoji,
    this.size = 220,
  });

  final PetMood mood;
  final String? accessoryEmoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _PetSprite(
              key: ValueKey(mood),
              mood: mood,
              size: size,
            ),
          ),
          if (accessoryEmoji != null)
            Positioned(
              top: size * 0.04,
              child: Text(
                accessoryEmoji!,
                style: TextStyle(fontSize: size * 0.22),
              ),
            ),
        ],
      ),
    );
  }
}

class _PetSprite extends StatelessWidget {
  const _PetSprite({super.key, required this.mood, required this.size});

  final PetMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/pet/${mood.assetName}.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _PlaceholderSprite(
        mood: mood,
        size: size,
      ),
    );
  }
}

class _PlaceholderSprite extends StatelessWidget {
  const _PlaceholderSprite({required this.mood, required this.size});

  final PetMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        mood.placeholderEmoji,
        style: TextStyle(fontSize: size * 0.4),
      ),
    );
  }
}
