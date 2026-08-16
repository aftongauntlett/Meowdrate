/// Shown every time the app is opened — cold launch or coming back from
/// the background — so the caption greets you instead of repeating
/// whatever drink-logged reaction was last showing. Milder and more
/// frequent than longAbsenceLines, which is reserved for the rarer
/// multi-day-gap case.
const appReturnLines = <String>[
  'Welcome back. The water hasn\'t moved.',
  'Oh, you again. I mean — welcome back.',
  'You return. The cat remains cautiously optimistic.',
  'Back so soon. Or not soon. I don\'t track that. Welcome back.',
  'You\'re here. The water\'s here. Let\'s pretend that\'s a coincidence.',
  'Welcome back. Try to act like you remember why you opened this.',
];
