/// Amount logged per "I drank" tap in the Drink Moment flow — one glass.
/// The daily goal is a configurable count of these (see
/// settings/providers/daily_goal_providers.dart), not a fixed ml number.
const kDrinkAmountMl = 250;

/// Duration of the pause-and-drink moment before "I drank" can be confirmed.
const kDrinkMomentSeconds = 15;
