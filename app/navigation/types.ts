import type { ParamListBase } from '@react-navigation/native';

export interface RootStackParamList extends ParamListBase {
  Home: { didLogDrink?: boolean } | undefined;
  DrinkMoment: undefined;
}
