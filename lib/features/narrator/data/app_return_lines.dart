/// Shown every time the app is opened during the day (7am–6pm local) —
/// cold launch or coming back from the background — so the caption greets
/// you instead of repeating whatever drink-logged reaction was last
/// showing. Dawn/dusk/night/late-night use their own pools; see
/// [selectAppReturnLine]. Milder and more frequent than longAbsenceLines,
/// which is reserved for the rarer multi-day-gap case.
const appReturnLines = <String>[
  'Welcome back. The water hasn\'t moved.',
  'Oh, you again. I mean — welcome back.',
  'You return. The cat remains cautiously optimistic.',
  'Back so soon. Or not soon. Either way, the water waited.',
  'You\'re here. The water\'s here. Let\'s pretend that\'s a coincidence.',
  'Welcome back. Try to act like you remember why you opened this.',
  'You opened the app. That\'s the easy part.',
  'Still flooded. Still you. Let\'s not make it a trilogy.',
  'Welcome back. I\'ve kept the flood exactly where you left it. You\'re welcome.',
  'You opened this. Step two is the glass, not the staring.',
  'The experiment continues. You are, unfortunately, still the subject.',
  'Good, you\'re here. The water was beginning to think this was a solo act.',
];
