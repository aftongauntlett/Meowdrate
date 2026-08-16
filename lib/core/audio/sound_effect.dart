enum SoundEffect {
  drinkLogged,
  goalMet,

  /// A single soft blip, played every few characters while the narrator's
  /// line types itself out in TypewriterText. Needs to be very short and
  /// quiet — it repeats dozens of times per line.
  narratorBlip,

  /// A soft UI click, played once per tap on the settings gear (open) and
  /// most controls inside the settings sheet — one shared tap sound rather
  /// than a distinct one per control, since none of these actions need
  /// their own identity. See [uiTapNegative] for the "closing/declining"
  /// counterpart.
  uiTap,

  /// The same soft UI click as [uiTap], pitched slightly lower — used for
  /// "closing/declining" taps specifically: the settings sheet's close (X)
  /// button, the "-" side of the daily-goal stepper, and "No" on the
  /// reset-today confirm dialog. Gives dismissive actions a distinct feel
  /// from [uiTap]'s neutral/affirmative one without needing a whole
  /// separate sound identity.
  uiTapNegative;

  /// Matches the file name expected in assets/audio/ — see that folder's
  /// README for how to self-produce these with jsfxr/bfxr.
  String get assetPath => 'audio/$name.mp3';
}
