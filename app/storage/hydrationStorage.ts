import AsyncStorage from '@react-native-async-storage/async-storage';

export interface HydrationDrinkEntry {
  timestamp: number;
  amountMl: number;
}

const STORAGE_KEY = 'hydration.drinks.v1';

interface StoredShape {
  drinks: HydrationDrinkEntry[];
}

async function read(): Promise<StoredShape> {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (!raw) {
    return { drinks: [] };
  }

  try {
    const parsed: unknown = JSON.parse(raw);
    if (
      typeof parsed === 'object' &&
      parsed !== null &&
      Array.isArray((parsed as { drinks?: unknown }).drinks)
    ) {
      return { drinks: (parsed as StoredShape).drinks };
    }
  } catch {
    // Ignore and reset storage.
  }

  return { drinks: [] };
}

async function write(value: StoredShape): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(value));
}

export async function getAllDrinks(): Promise<HydrationDrinkEntry[]> {
  const data = await read();
  return data.drinks;
}

export async function appendDrink(entry: HydrationDrinkEntry): Promise<void> {
  const data = await read();
  await write({ drinks: [...data.drinks, entry] });
}
