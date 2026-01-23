import { appendDrink, getAllDrinks, type HydrationDrinkEntry } from '../storage/hydrationStorage';

export interface DrinkAmount {
  amountMl: number;
}

export interface DrinksTodaySummary {
  count: number;
  totalAmountMl: number;
  recent: HydrationDrinkEntry[];
}

function getStartOfTodayMs(now: Date): number {
  const start = new Date(now);
  start.setHours(0, 0, 0, 0);
  return start.getTime();
}

function getStartOfTomorrowMs(now: Date): number {
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(0, 0, 0, 0);
  return tomorrow.getTime();
}

async function logDrink(amountMl: number): Promise<HydrationDrinkEntry> {
  const entry: HydrationDrinkEntry = {
    timestamp: Date.now(),
    amountMl,
  };

  await appendDrink(entry);
  return entry;
}

async function getDrinksTodayCount(now: Date = new Date()): Promise<number> {
  const drinks = await getAllDrinks();
  const start = getStartOfTodayMs(now);
  const end = getStartOfTomorrowMs(now);

  return drinks.filter((drink) => drink.timestamp >= start && drink.timestamp < end).length;
}

async function getDrinksToday(now: Date = new Date()): Promise<HydrationDrinkEntry[]> {
  const drinks = await getAllDrinks();
  const start = getStartOfTodayMs(now);
  const end = getStartOfTomorrowMs(now);

  return drinks
    .filter((drink) => drink.timestamp >= start && drink.timestamp < end)
    .sort((a, b) => b.timestamp - a.timestamp);
}

async function getDrinksTodaySummary(now: Date = new Date()): Promise<DrinksTodaySummary> {
  const drinksToday = await getDrinksToday(now);
  const totalAmountMl = drinksToday.reduce((sum, entry) => sum + entry.amountMl, 0);

  return {
    count: drinksToday.length,
    totalAmountMl,
    recent: drinksToday.slice(0, 5),
  };
}

export const hydrationService = {
  logDrink,
  getDrinksTodayCount,
  getDrinksToday,
  getDrinksTodaySummary,
};
