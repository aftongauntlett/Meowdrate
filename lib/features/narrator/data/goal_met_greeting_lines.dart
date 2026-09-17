/// Shown on app open/resume — any time of day — when today's goal is
/// already met. Overrides the dawn/dusk/night/late-night/appReturn pools,
/// which otherwise assume the flood is still up; one shared pool rather
/// than hour-flavored variants, since "you're already done" doesn't need
/// to know what time it is.
const goalMetGreetingLines = <String>[
  'Goal\'s already met. You\'re just here for the encore, apparently.',
  'Nothing left to fix today. The cat\'s dry, and so is your excuse to keep checking.',
  'You did the thing. The water\'s gone. This is what winning looks like around here.',
  'Already finished today. Showing off, or just making sure I noticed?',
  'The flood\'s cleared. You\'re still here. I don\'t mind the company.',
  'All done for today. Everything after this is just a victory lap.',
  'Today\'s handled. The cat approves, in its way.',
  'Nothing\'s waiting on you right now. Strange feeling, isn\'t it?',
];
