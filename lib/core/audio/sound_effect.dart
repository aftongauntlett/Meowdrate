enum SoundEffect {
  drinkLogged,
  goalMet,

  /// Reserved, not yet wired anywhere: a distinct "a creature was just
  /// rescued" moment separate from goalMet. Draining the flood *is*
  /// meeting the goal in the current mechanic, so there's only one real
  /// trigger today — this is named ahead of time to match the PRD's
  /// three self-made sound effects, for whenever the scene grows a
  /// separate reveal moment.
  creatureRescued;

  /// Matches the file name expected in assets/audio/ — see that folder's
  /// README for how to self-produce these with jsfxr/bfxr.
  String get assetPath => 'audio/$name.mp3';
}
