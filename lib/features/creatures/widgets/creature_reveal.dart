import 'package:flutter/material.dart';

import '../models/creature.dart';
import '../models/mood_band.dart';
import 'sprite_animation.dart';

class CreatureReveal extends StatelessWidget {
  const CreatureReveal({
    super.key,
    required this.creature,
    required this.mood,
    this.size = 128,
  });

  final Creature creature;
  final MoodBand mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SpriteAnimation(creature: creature, mood: mood, scale: size / creature.frameSize);
  }
}
