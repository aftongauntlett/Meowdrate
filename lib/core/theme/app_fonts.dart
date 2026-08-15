/// The pixel/typewriter face used for headings across the app — home's
/// "Recent" label, Settings' section titles and daily-goal readout, Drink
/// Moment's headline and countdown — so they all read as one system rather
/// than the default body font (Inter) leaking into places meant to feel
/// like game UI. Narrator dialogue also uses this family directly (see
/// narrator/widgets/typewriter_text.dart) but for a different reason —
/// there it's the "terminal" voice, not a heading.
const kHeadingFontFamily = 'Courier Prime';
